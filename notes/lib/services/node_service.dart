part of services;

/// A [NodeService] class responsible for managing node operations within a hierarchical structure.
///
/// This class encapsulates functionalities for creating, deleting, renaming, and moving nodes
/// within a hierarchy. Nodes can represent either a note or a folder, and operations can affect
/// their position or existence within the hierarchy. The service interacts with both the hierarchy
/// database and the notes database to ensure data consistency.
///
/// ## Usage:
/// Instantiate `NodeService` with optional custom [HierarchyDatabase] and [NotesDatabase] instances
/// for managing the hierarchy and notes.
///
/// ## Example:
/// ```dart
/// NodeService nodeService = NodeService();
/// MyTreeNode parentNode = ...; // Assuming parentNode is already defined
/// nodeService.createNewNode(parentNode, "New Node Name", isNote: true);
/// ```
class NodeService {
  /// [HierarchyDatabase] instance for interacting with the hierarchy local storage.
  HierarchyDatabase hierarchyDb;

  /// [NotesDatabase] instance for interacting with the notes local storage.
  NotesDatabase notesDatabase;

  /// [ComponentUtils] instance for utility functions, such as showing error messages.
  ComponentUtils utils = ComponentUtils();

  /// Constructor for [NodeService]. Allows injection of [HierarchyDatabase] and [NotesDatabase]
  /// for flexibility and testing purposes. If not provided, default instances are used.
  NodeService({
    HierarchyDatabase? hierarchyDb,
    NotesDatabase? notesDatabase,
  })  : hierarchyDb = hierarchyDb ?? HierarchyDatabase(),
        notesDatabase = notesDatabase ?? NotesDatabase();

  /// Deletes a given node and, if applicable, its descendants from the hierarchy and notes database.
  /// The deletion cascades to all children of the node to ensure data integrity.
  ///
  /// - [node]: The node to be deleted.
  /// - [parent]: The parent of the node being deleted.
  void deleteNode(MyTreeNode node, MyTreeNode? parent) {
    //AppLogger.log('Deleting node ${node.id}');
    // If node is note, delete note
    if (node.isNote) {
      notesDatabase.deleteNote(node.id);
      hierarchyDb.deleteNote(node.id);
    }
    // If node have children -> delete its notes
    for (MyTreeNode child in node.children) {
      deleteNode(child, node);
    }
    updateRootLastChange(node.id);
    if (parent == null) {
      hierarchyDb.deleteRoot(node);
    } else {
      parent.children.remove(node);
      hierarchyDb.updateDatabase();
    }
  }

  /// Renames a given node in the hierarchy and updates the database accordingly.
  /// Checks are performed to ensure the new name is valid and unique among siblings.
  ///
  /// - [node]: The node to be renamed.
  /// - [newName]: The new name for the node.
  /// - Returns `true` if the rename operation is successful; otherwise, `false`.
  bool renameNode(MyTreeNode node, String newName, BuildContext context) {
    //AppLogger.log('Renaming node ${node.id}');
    if (newName.isEmpty) {
      //AppLogger.log("The name is empty", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.emptyTextFieldToast);
      return false;
    } else if (containsDisabledChars(newName)) {
      //AppLogger.log("Disabled chars", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.disabledCharsToast);
      return false;
    } else if (siblingWithSameName(node.id, newName, false)) {
      //AppLogger.log("Sibling with same name", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.siblingWithSameNameToast);
      return false;
    } else {
      node.title = newName;
      String newId = changeNameInId(node.id, newName);
      if (node.isNote) {
        notesDatabase.changeNoteId(node.id, newId);
        hierarchyDb.updateNote(node.id, newId);
      }
      if (isRoot(node.id)) {
        hierarchyDb.updateRoot(node.id, newId);
      }
      node.id = newId;
      for (MyTreeNode child in node.children) {
        changeId(child, newId);
      }
      hierarchyDb.updateDatabase();
      updateRootLastChange(node.id);
      return true;
    }
  }

  /// Creates a new node under a specified parent node with the given name and type.
  /// Validates the node name and ensures uniqueness within the sibling nodes.
  ///
  /// - [node]: The parent node under which the new node will be created.
  /// - [nodeName]: The name of the new node.
  /// - [nodeType]: The type of the new node (note or folder).
  /// - Returns `true` if the node is successfully created; otherwise, `false`.
  bool createNewNode(MyTreeNode node, String nodeName, bool nodeType, BuildContext context) {
    //AppLogger.log('Creating new node');
    if (nodeName.isEmpty) {
      //AppLogger.log("The name is empty", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.emptyTextFieldToast);
      return false;
    } else if (containsDisabledChars(nodeName)) {
      //AppLogger.log("Disabled chars", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.disabledCharsToast);
      return false;
    } else if (siblingWithSameName(node.id, nodeName, true)) {
      //AppLogger.log("Sibling with same name", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.siblingWithSameNameToast);
      return false;
    } else {
      String nodeId = node.id + DELIMITER + nodeName;
      MyTreeNode newNode =
          MyTreeNode(id: nodeId, title: nodeName, isNote: nodeType, isLocked: false);
      node.addChild(newNode);
      hierarchyDb.updateDatabase();
      if (nodeType) {
        notesDatabase.createNote(nodeId);
        hierarchyDb.addNote(nodeId);
      }
      updateRootLastChange(node.id);
      return true;
    }
  }

  /// Moves a node to a new parent within the hierarchy and updates the database.
  ///
  /// - [node]: The node to be moved.
  /// - [newParent]: The ID of the new parent node.
  /// - Returns `true` if the move operation is successful; otherwise, `false`.
  bool moveNode(MyTreeNode node, String newParent, BuildContext context) {
    //AppLogger.log('Moving node ${node.id}, new parent: $newParent');
    MyTreeNode? parent = getNode(newParent);
    if (parent == null) {
      return false;
      // return error
    } else {
      for (var sibling in parent.children) {
        if (sibling.title == node.title) {
          ComponentUtils.showErrorToast(AppLocalizations.of(context)!.siblingWithSameNameToast);
          return false;
        }
      }
      MyTreeNode? oldParent = getParent(node.id);
      if (oldParent != null) {
        oldParent.children.remove(node);
      } else {
        hierarchyDb.deleteRoot(node);
      }
      parent.addChild(node);
      String oldNoteId = node.id;
      node.id = newParent + DELIMITER + node.title;
      if (node.isNote) {
        notesDatabase.changeNoteId(oldNoteId, node.id);
        hierarchyDb.updateNote(oldNoteId, node.id);
      }
      for (MyTreeNode child in node.children) {
        changeId(child, node.id);
      }
      hierarchyDb.updateDatabase();
      updateRootLastChange(node.id);
      return true;
    }
  }

  /// Creates a new root node with the given name.
  ///
  /// - [name] is the name of the new root node.
  /// - [context] is the build context for accessing localized strings.
  ///
  /// Returns true if the root node is successfully created, otherwise returns false.
  bool createNewRoot(String name, bool isNote, BuildContext context) {
    String id = DELIMITER + name;
    if (name.isEmpty) {
      //AppLogger.log("The name is empty", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.emptyTextFieldToast);
      return false;
    } else if (containsDisabledChars(name)) {
      //AppLogger.log("Disabled chars", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.disabledCharsToast);
      return false;
    } else if (HierarchyDatabase.rootList.contains(id)) {
      //AppLogger.log("Root with same name", level: Level.WARNING);
      ComponentUtils.showErrorToast(AppLocalizations.of(context)!.siblingWithSameNameToast);
      return false;
    }
    MyTreeNode newRoot = MyTreeNode(id: id, title: name, isNote: isNote, isLocked: false);
    hierarchyDb.saveRoot(newRoot);
    return true;
  }

  /// Locks the specified node with the given password.
  ///
  /// - [password] is the password used to lock the node.
  /// - [node] is the node to be locked.
  ///
  /// Returns true if the node is successfully locked, otherwise returns false.
  bool lockNode(String password, MyTreeNode node) {
    String hash = generateHash(password);
    node.isLocked = true;
    node.password = hash;
    return true;
  }

  /// Unlocks the specified node with the given password.
  ///
  /// - [password] is the password used to unlock the node.
  /// - [node] is the node to be unlocked.
  ///
  /// Returns true if the node is successfully unlocked, otherwise returns false.
  bool unlockNode(String password, MyTreeNode node) {
    if (comparePassword(password, node.password!)) {
      node.isLocked = false;
      node.password = null;
      return true;
    } else {
      return false;
    }
  }

  /// Retrieves a node from the hierarchy based on its unique ID.
  ///
  /// - [nodeId]: The unique ID of the node to retrieve.
  /// - Returns the [MyTreeNode] if found; otherwise, `null`.
  MyTreeNode? getNode(String nodeId) {
    List<String> path = nodeId.split(DELIMITER);
    log("$path");
    int level = 1;
    hierarchyDb.loadData();
    List<MyTreeNode> nodeList = HierarchyDatabase.roots;
    log("Starting serching, nodeList: $nodeList");
    return searchChildren(level, nodeList, path);
  }

  /// Searches the hierarchy recursively to find a node matching the provided path.
  ///
  /// - [level]: The current level in the hierarchy being searched.
  /// - [nodeList]: The list of nodes at the current level.
  /// - [path]: The list of titles representing the path to the node.
  /// - Returns the matching [MyTreeNode] if found; otherwise, `null`.
  MyTreeNode? searchChildren(int level, List<MyTreeNode> nodeList, List<String> path) {
    log("Search children ${path.elementAt(level)}");
    for (MyTreeNode node in nodeList) {
      if (level == path.length - 1 && node.title == path[level]) {
        return node;
      }
      if (node.title == path[level]) {
        return searchChildren(level + 1, node.children, path);
      }
    }
    return null;
  }

  /// Retrieves the parent node of a given node based on the node's unique ID.
  ///
  /// - [nodeId]: The unique ID of the node whose parent is to be found.
  /// - Returns the parent [MyTreeNode] if found; otherwise, `null`.
  MyTreeNode? getParent(String nodeId) {
    log("Getting parent");
    List<String> path = nodeId.split(DELIMITER);
    int level = 1;
    hierarchyDb.loadData();
    List<MyTreeNode> nodeList = HierarchyDatabase.roots;
    return searchParent(level, nodeList, path, null);
  }

  /// Searches the hierarchy recursively to find the parent of a node matching the provided path.
  ///
  /// - [level]: The current level in the hierarchy being searched.
  /// - [nodeList]: The list of nodes at the current level.
  /// - [path]: The list of titles representing the path to the node.
  /// - [parent]: The current parent node in the search.
  /// - Returns the matching parent [MyTreeNode] if found; otherwise, `null`.
  MyTreeNode? searchParent(
      int level, List<MyTreeNode> nodeList, List<String> path, MyTreeNode? parent) {
    log("Search parent ${path.elementAt(level)}");
    for (MyTreeNode node in nodeList) {
      if (level == path.length - 1 && node.title == path[level]) {
        return parent;
      }
      if (node.title == path[level]) {
        return searchParent(level + 1, node.children, path, node);
      }
    }
    return null;
  }

  /// Checks if the provided name contains any characters that are not allowed.
  ///
  /// - [name]: The name to check for disallowed characters.
  /// - Returns `true` if disallowed characters are found; otherwise, `false`.
  bool containsDisabledChars(String name) {
    for (String disabledChar in DISABLED_CHARS) {
      if (name.contains(disabledChar)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a sibling node with the same name already exists.
  ///
  /// - [nodeId]: The ID of the node whose siblings are to be checked.
  /// - [newName]: The name to check for among the siblings.
  /// - [newNode]: Specifies whether the check is for a new node being added.
  /// - Returns `true` if a sibling with the same name exists; otherwise, `false`.
  bool siblingWithSameName(String nodeId, String newName, bool newNode) {
    MyTreeNode? parent;
    if (newNode) {
      parent = getNode(nodeId);
    } else {
      parent = getParent(nodeId);
    }
    log("Parent: $parent");
    if (parent == null) {
      return false;
    } else {
      for (MyTreeNode sibling in parent.children) {
        if (sibling.title == newName) {
          return true;
        }
      }
    }
    return false;
  }

  /// Changes the ID of a node and its children to reflect a new hierarchy path.
  ///
  /// - [node]: The node whose ID is to be changed.
  /// - [path]: The new path to incorporate into the node's ID.
  void changeId(MyTreeNode node, String path) {
    String newId = changePathInId(node.id, path);
    if (node.isNote) {
      notesDatabase.changeNoteId(node.id, newId);
      hierarchyDb.updateNote(node.id, newId);
    }
    node.id = newId;
    for (MyTreeNode child in node.children) {
      changeId(child, node.id);
    }
  }

  /// Constructs a new ID for a node by changing its name within its existing ID.
  ///
  /// - [actualPath]: The current ID of the node.
  /// - [newFileName]: The new name to be incorporated into the node's ID.
  /// - Returns the newly constructed ID incorporating the new name.
  String changeNameInId(String actualPath, String newFileName) {
    List<String> path = actualPath.split(DELIMITER);
    String newId = "";
    for (int i = 1; i < path.length - 1; i++) {
      newId += DELIMITER + path[i];
    }
    newId += DELIMITER + newFileName;
    return newId;
  }

  /// Constructs a new ID for a node by changing its path within its existing ID.
  ///
  /// - [path]: The current ID of the node.
  /// - [newPath]: The new path to be incorporated into the node's ID.
  /// - Returns the newly constructed ID incorporating the new path.
  String changePathInId(String path, String newPath) {
    List<String> splittedPath = path.split(DELIMITER);
    String fileName = splittedPath[splittedPath.length - 1];
    return newPath + DELIMITER + fileName;
  }

  /// Returns the path to the parent of a node based on the node's ID.
  ///
  /// - [path]: The ID of the node.
  /// - Returns the path to the parent node.
  String getParentPath(String path) {
    List<String> splittedPath = path.split(DELIMITER);
    String parentPath = "";
    for (int i = 1; i < splittedPath.length - 1; i++) {
      parentPath += DELIMITER + splittedPath[i];
    }
    return parentPath;
  }

  /// Returns a list of all folder IDs within the hierarchy.
  ///
  /// - Returns a list of folder IDs.
  List<String> getAllFolders() {
    List<String> folders = [];
    for (MyTreeNode node in HierarchyDatabase.roots) {
      getFolders(folders, node);
    }
    return folders;
  }

  /// Recursively adds folder IDs to a provided list, starting from a given node.
  ///
  /// - [folders]: The list to which folder IDs are added.
  /// - [node]: The starting node for adding folder IDs.
  void getFolders(List<String> folders, MyTreeNode node) {
    if (!node.isNote) {
      folders.add(node.id);
    }
    for (MyTreeNode child in node.children) {
      getFolders(folders, child);
    }
  }

  /// Generates a list of folder IDs suitable for moving a given node.
  ///
  /// This method filters out the node itself, its direct parent and its childrens
  /// from the list of all folders to prevent errors.
  ///
  /// - [node]: The node that is to be moved.
  /// - Returns a list of folder IDs excluding the node and its parent.
  List<String> getFoldersToMove(MyTreeNode node) {
    List<String> folders = getAllFolders();
    if (!node.isNote) {
      folders.remove(node.id);
    }
    folders.remove(getParentPath(node.id));
    return folders;
  }

  /// Controls if the given nodeId represents a root node in the hierarchy.
  ///
  /// - [nodeId]: The ID of the node to check.
  /// - Returns `true` if the node is a root node; otherwise, `false`.
  bool isRoot(String nodeId) {
    for (String root in HierarchyDatabase.rootList) {
      if (root == nodeId) {
        return true;
      }
    }
    return false;
  }

  /// Generates a SHA-256 hash for the given password.
  ///
  /// [password] is the password to be hashed.
  ///
  /// Returns the hashed password as a string.
  String generateHash(String password) {
    var bytes = utf8.encode(password);
    var hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Compares the input password with the stored hash.
  ///
  /// [inputPassword] is the password provided by the user.
  /// [storedHash] is the hashed password stored in the database.
  ///
  /// Returns true if the input password matches the stored hash, otherwise returns false.
  bool comparePassword(String inputPassword, String storedHash) {
    var inputHash = generateHash(inputPassword);
    return inputHash == storedHash;
  }

  /// Updates the last change time for the root node identified by [nodeId].
  ///
  /// [nodeId] is the identifier of the node whose root's change time needs to be updated.
  void updateRootLastChange(String nodeId) {
    List<String> splittedPath = nodeId.split(DELIMITER);
    String rootId = DELIMITER + splittedPath[1];
    log("Changing root change time: $rootId");
    hierarchyDb.updateRootLastChangeTime(rootId);
  }

  /// Saves a conflict version of all root nodes to the database with
  ///  a unique identifier based on the current date and time.
  void saveAllConflictData() {
    String conflictName = CONFLICT + DateTime.now().toString();
    MyTreeNode newConflict = MyTreeNode(
      id: conflictName,
      title: conflictName,
      isNote: false,
      isLocked: false,
    );
    for (MyTreeNode root in HierarchyDatabase.roots) {
      changeId(root, conflictName);
      newConflict.addChild(root);
    }
    hierarchyDb.saveConflict(newConflict);
  }

  /// Saves a conflict version of a specific root node, identified by [rootId], with a unique identifier based on the current date and time.
  ///
  /// [rootId] is ID of the root node to save as a conflict.
  void saveConflictRoot(String rootId) {
    String conflictName = rootId + DateTime.now().toString();
    MyTreeNode conflictRoot = hierarchyDb.getRoot(rootId);
    String newId = changeNameInId(conflictRoot.id, conflictName);
    for (MyTreeNode child in conflictRoot.children) {
      changeId(child, newId);
    }
    hierarchyDb.saveConflict(conflictRoot);
  }

  /// Saves a conflict version of a specific note, identified by [noteId], with a unique identifier based on the current date and time.
  ///
  /// [noteId] is ID of the note to save as a conflict.
  void saveConflictNote(String noteId) {
    List<String> path = noteId.split(DELIMITER);
    String conflictName = path[path.length - 1] + DateTime.now().toString();
    MyTreeNode conflictNote =
        MyTreeNode(id: conflictName, title: conflictName, isNote: true, isLocked: false);
    hierarchyDb.saveConflictNote(conflictNote, noteId);
  }

  /// Deletes a conflict node from the database.
  ///
  /// [conflictNode] is conflict node to delete.
  void deleteConflict(MyTreeNode conflictNode) {
    log("Deleting: ${conflictNode.id}");
    if (conflictNode.isNote) {
      deleteConflictNote(conflictNode);
    }
    List<String> path = conflictNode.id.split(DELIMITER);
    MyTreeNode conflitRoot = hierarchyDb.getConflictNode();
    int level = 0;
    deleteConflictNode(level, conflitRoot, path);
    hierarchyDb.saveConflictNode(conflitRoot);
  }

  /// Deletes a conflict note recursively from the database.
  ///
  /// [conflictNode] The conflict note to delete.
  void deleteConflictNote(MyTreeNode conflictNode) {
    if (conflictNode.isNote) {
      hierarchyDb.deleteConflictNote(conflictNode.id);
    }
    for (MyTreeNode child in conflictNode.children) {
      deleteConflictNote(child);
    }
  }

  /// Recursively deletes a conflict node matching a specific path from the parent node.
  ///
  /// [level] is current level of depth in the hierarchy being checked.
  /// [parent] is parent node containing children to check against.
  /// [path]: is a list representing the path to match for deletion.
  void deleteConflictNode(int level, MyTreeNode parent, List<String> path) {
    bool found = false;
    MyTreeNode? foundedNode;
    for (MyTreeNode child in parent.children) {
      log("Child: ${child.id}, Path: $path, Level: $level");
      if (child.title == path[level] && level == path.length - 1) {
        found = true;
        foundedNode = child;
      } else if (child.title == path[level]) {
        deleteConflictNode(level + 1, child, path);
      }
    }
    if (found) {
      parent.children.remove(foundedNode);
    }
  }
}
