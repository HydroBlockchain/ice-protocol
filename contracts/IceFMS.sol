pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./SafeMath8.sol";

import "./IceGlobal.sol";
import "./IceSort.sol";

import "./IceFMSAdv.sol";

/**
 * @title Ice Protocol Files / Groups / Users Meta Management System Libray
 * @author Harsh Rajat
 * @notice Create sorting order for maximizing space utilization
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceFMS {
    using SafeMath for uint;
    using SafeMath8 for uint8;
    
    using IceGlobal for IceGlobal.GlobalRecord;
    using IceGlobal for IceGlobal.Association;
    using IceGlobal for IceGlobal.UserMeta;
    using IceGlobal for mapping (uint => bool);
    using IceGlobal for mapping (uint8 => IceGlobal.ItemOwner);
    using IceGlobal for mapping (uint => mapping (uint => IceGlobal.Association));
    using IceGlobal for uint;
    
    using IceSort for mapping (uint => IceSort.SortOrder);
    using IceSort for IceSort.SortOrder;
    
    using IceFMSAdv for mapping (uint => mapping(uint => IceGlobal.GlobalRecord));
    
    
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    /* To define the multihash function for storing of hash */
    struct FileMeta {
        bytes32 name; // to store the name of the file
        
        bytes32 hash; // to store the hash of file
        bytes22 hashExtraInfo; // to store any extra info if required
        
        bool encrypted; // whether the file is encrypted
        bool markedForTransfer; // Mark the file as transferred
        
        uint8 protocol; // store protocol of the file stored | 0 is URL, 1 is IPFS
        uint8 transferCount; // To maintain the transfer count for mapping
        
        uint8 hashFunction; // Store the hash of the file for verification | 0x000 for deleted files
        uint8 hashSize; // Store the length of the digest
        
        uint32 timestamp;  // to store the timestamp of the block when file is created
    }
    
    /* To define File structure of all stored files */
    struct File {
        // File Meta Data
        IceGlobal.GlobalRecord rec; // store the association in global record

        // File Properties
        bytes protocolMeta; // store metadata of the protocol
        FileMeta fileMeta; // store metadata associated with file

        // File Properties - Encryption Properties
        mapping (address => bytes32) encryptedHash; // Maps Individual address to the stored hash

        // File Other Properties
        uint associatedGroupIndex; // to store the group index of the group that holds the file
        uint associatedGroupFileIndex; // to store the mapping of file in the specific group order
        uint transferEIN; // To record EIN of the user to whom trasnfer is inititated
        uint transferIndex; // To record the transfer specific index of the transferee

        // File Transfer Properties
        mapping (uint => uint) transferHistory; // To maintain histroy of transfer of all EIN
    }

    /* To connect Files in linear grouping,
     * sort of like a folder, 0 or default grooupID is root
     */
    struct Group {
        IceGlobal.GlobalRecord rec; // store the association in global record

        string name; // the name of the Group

        mapping (uint => IceSort.SortOrder) groupFilesOrder; // the order of files in the current group
        uint groupFilesCount; // To keep the count of group files
    }
     
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. FILE FUNCTIONS
    /**
     * @dev Function to get file info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return protocol returns the protocol used for storage of the file (0 - URL, 1 - IPFS)
     * @return protocolMeta returns the meta info associated with a protocol
     * @return fileName is the name of the file
     * @return fileHash is the Hash of the file
     * @return hashExtraInfo is extra info stored as part of the protocol used 
     * @return hashFunction is the function used to store that hash
     * @return hashSize is the size of the digest
     * @return encryptedStatus indicates if the file is encrypted or not 
     */
    function getFileInfo(File storage self)
    external view
    returns (
        uint8 protocol, 
        bytes memory protocolMeta, 
        string memory fileName, 
        bytes32 fileHash, 
        bytes22 hashExtraInfo,
        uint8 hashFunction,
        uint8 hashSize,
        bool encryptedStatus
    ) {
        // Logic
        protocol = self.fileMeta.protocol; // Protocol
        protocolMeta = self.protocolMeta; // Protocol meta
        
        fileName = bytes32ToString(self.fileMeta.name); // File Name, convert from byte32 to string
        
        fileHash = self.fileMeta.hash; // hash of the file
        hashExtraInfo = self.fileMeta.hashExtraInfo; // extra info of hash of the file (to utilize 22 bytes of wasted space)
        hashFunction = self.fileMeta.hashFunction; // the hash function used to store the file
        hashSize = self.fileMeta.hashSize; // The length of the digest
        
        encryptedStatus = self.fileMeta.encrypted; // Whether the file is encrypted or not
    }
    
    /**
     * @dev Function to get file info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return timestamp indicates the timestamp of the file
     * @return associatedGroupIndex indicates the group which the file is associated to in the user's FMS
     * @return associatedGroupFileIndex indicates the file index within the group of the user's FMS
     */
    function getFileOtherInfo(File storage self)
    external view
    returns (
        uint32 timestamp, 
        uint associatedGroupIndex, 
        uint associatedGroupFileIndex
    ) {
        // Logic
        timestamp = self.fileMeta.timestamp;
        associatedGroupIndex = self.associatedGroupIndex;
        associatedGroupFileIndex = self.associatedGroupFileIndex;
    }

    /**
     * @dev Function to get file tranfer info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return transferCount indicates the number of times the file has been transferred
     * @return transferEIN indicates the EIN of the user to which the file is currently scheduled for transfer
     * @return transferIndex indicates the transfer index of the target EIN where the file is currently mapped to
     * @return markedForTransfer indicates if the file is marked for transfer or not
     */
    function getFileTransferInfo(File storage self)
    external view
    returns (
        uint transferCount, 
        uint transferEIN, 
        uint transferIndex, 
        bool markedForTransfer
    ) {
        // Logic
        transferCount = self.fileMeta.transferCount; 
        transferEIN = self.transferEIN; 
        transferIndex = self.transferIndex; 
        markedForTransfer = self.fileMeta.markedForTransfer;
    }

    /**
     * @dev Function to get file tranfer owner info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transferIndex is index to poll which is useful to get the history of transfers and to what EIN the file previously belonged to
     * @return previousOwnerEIN is the EIN of the user who had originally owned that file
     */
    function getFileTransferOwners(
        File storage self, 
        uint _transferIndex
    )
    external view
    returns (uint previousOwnerEIN) {
        previousOwnerEIN = self.transferHistory[_transferIndex];    // Return transfer history associated with a particular transfer index
    }
    
    /**
     * @dev Function to create a basic File Object for a given file
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _protocolMeta is the meta info which is stored for a certain protocol
     * @return _groupIndex is the index of the group where the file is stored
     * @return _groupFilesCount is the number of files stored in that group 
     */
    function createFileObject(
        File storage self,
        bytes calldata _protocolMeta,
        uint _groupIndex, 
        uint _groupFilesCount
    )
    external {
        // Set other File info
        self.protocolMeta = _protocolMeta;
        
        self.associatedGroupIndex = _groupIndex;
        self.associatedGroupFileIndex = _groupFilesCount;
    }
    
    /**
     * @dev Function to create a File Meta Object and attach it to File Struct (IceFMS Library)
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _protocol is type of protocol used to store that file (0 - URL, 1- IPFS)
     * @param _name is the name of the file with the extension
     * @param _hash is the hash of the file (useful for IPFS and to verify authenticity)
     * @param _hashExtraInfo is the extra info which can be stored in a 22 byte format (if required)
     * @param _hashFunction is the function used to generate the hash
     * @param _hashSize is the size of the digest
     * @param _encrypted indicates if the file is encrypted or not  
     */
    function createFileMetaObject(
        File storage self,
        uint8 _protocol,
        bytes32 _name, 
        bytes32 _hash,
        bytes22 _hashExtraInfo,
        uint8 _hashFunction,
        uint8 _hashSize,
        bool _encrypted
    )
    external {
        //set file meta
        self.fileMeta = FileMeta(
            _name,                  // to store the name of the file
            
            _hash,                  // to store the hash of file
            _hashExtraInfo,         // to store any extra info if required
            
            _encrypted,             // whether the file is encrypted
            false,                  // Mark the file as transferred, defaults to false
                
            _protocol,              // store protocol of the file stored | 0 is URL, 1 is IPFS
            1,                      // Default transfer count is 1
            
            _hashFunction,          // Store the hash of the file for verification | 0x000 for deleted files
            _hashSize,              // Store the length of the digest
            
            uint32(now)             // to store the timestamp of the block when file is created
        );
    }
    
    /**
     * @dev Function to write file to a user FMS
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param group is the pointer to the group where the file is going to be stored for the primary user (EIN)
     * @param _groupIndex indicates the index of the group for the EIN's FMS
     * @param _userFileOrderMapping is the mapping of the user's file order using SortOrder Struct (IceSort Library)
     * @param _maxFileIndex indicates the maximum index of the files stored for the primary user (EIN)
     * @param _nextIndex indicates the next index which will store the particular file in question
     * @param _transferEin is the EIN of the user for which the file is getting written to, defaults to primary user
     * @param _encryptedHash is the encrypted hash stored incase the file is encrypted
     */
    function writeFile(
        File storage self, 
        Group storage group, 
        uint _groupIndex, 
        mapping(uint => IceSort.SortOrder) storage _userFileOrderMapping, 
        uint _maxFileIndex, 
        uint _nextIndex, 
        uint _transferEin, 
        bytes32 _encryptedHash
    ) 
    external 
    returns (uint newFileCount) {
        // Add file to group 
        (self.associatedGroupIndex, self.associatedGroupFileIndex) = addFileToGroup(group, _groupIndex, _nextIndex);
        
        // To map encrypted password
        self.encryptedHash[msg.sender] = _encryptedHash;

        // To map transfer history
        self.transferHistory[0] = _transferEin;

        // Add to Stitch Order & Increment index
        newFileCount = _userFileOrderMapping.addToSortOrder(_userFileOrderMapping[0].prev, _maxFileIndex, 0);
    }
    
    /**
     * @dev Function to move file to another group
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _fileIndex is the file index in the user's FMS files mapping
     * @param _groupMapping is the mapping of all groups for the user's FMS
     * @param _groupOrderMapping is the mapping of the order of files in that group for the primary user's FMS
     * @param _newGroupIndex is the index of the new group where file has to be moved
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @return groupFileIndex is the index of the file stored in that relevant group of the primary user 
     */
    function moveFileToGroup(
        File storage self, 
        uint _fileIndex,
        mapping(uint => IceFMS.Group) storage _groupMapping, 
        mapping(uint => IceSort.SortOrder) storage _groupOrderMapping,
        uint _newGroupIndex,
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external 
    returns (uint groupFileIndex){
        // Check Restrictions
        _groupOrderMapping[_newGroupIndex].condValidSortOrder(_newGroupIndex); // Check if the new group is valid
        self.rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check if the file is unstamped, can't move a stamped file
        
        // Check if the current group is unstamped, can't move a file from stamped group
        _groupMapping[self.associatedGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); 
        
        // Check if the new group is unstamped, can't move a file from stamped group
        _groupMapping[_newGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); 
        
        // remap the file
        groupFileIndex = remapFileToGroup(
            self, 
            _fileIndex,
            _groupMapping[self.associatedGroupIndex], 
            _groupMapping[_newGroupIndex], 
            _newGroupIndex
        );
    }

    /**
     * @dev Function to delete file of the owner
     * @param self is the mapping of all pointer to the File Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _fileIndex is the index where file is stored
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _fileOrderMapping is the mapping of the files of the primary user's FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _fileGroup is the Group Struct (IceFMS Library) under which the file in question is stored
     * @param _fileGroupOrder is the SortOrder Struct (IceSort Library) which points to the order of the file in the user's group
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function deleteFile(
        mapping (uint => File) storage self,
        uint _ein,
        uint _fileIndex,
        IceGlobal.Association storage _globalItemIndividual,
        
        mapping (uint => IceSort.SortOrder) storage _fileOrderMapping,
        mapping (uint => uint) storage _fileCountMapping,
        Group storage _fileGroup,
        IceSort.SortOrder storage _fileGroupOrder,
        
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    )
    public {
        // Check Restrictions
        _fileIndex.condValidItem(_fileCountMapping[_ein]); // Check if the file exists first
        _globalItemIndividual.condUnstampedItem(); // Check if the file is unstamped, can't delete a stamped file
        _fileGroupOrder.condValidSortOrder(self[_fileIndex].associatedGroupFileIndex); //Check if sort order is valid
        condItemMarkedForTransfer(self[_fileIndex]);// Check if the File is not marked for transfer
        
        // Delete File Shares and Global Mapping
        _deleteFileMappings(
            _ein, 
            _globalItemIndividual, 
            _totalSharesMapping, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Delete the latest file now
        delete (self[_fileIndex]);
        
        // Delete File Object
        _deleteFileObject(
            self, 
            _ein, 
            _fileIndex, 
            _fileOrderMapping, 
            _fileCountMapping, 
            _fileGroup
        );
    }
    
    /**
     * @dev Private Function to delete file mappings from a user's FMS system
     * @param _ein is the EIN of the user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function _deleteFileMappings(
        uint _ein,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    ) 
    internal {
        // Remove item from sharing of other users
        _totalSharesMapping.removeAllShares(
            _ein,
            _globalItemIndividual, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Remove from global Record
        _globalItemIndividual.deleteGlobalRecord();
    }
    
    /**
     * @dev Private Function to delete file mappings from a user's FMS system
     * @param _files is the mapping of all pointer to the File Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the user
     * @param _fileIndex is the file index in the user's FMS files mapping
     * @param _fileOrderMapping is the mapping of the files of the primary user's FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _fileGroup is the Group Struct (IceFMS Library) under which the file in question is stored
     */
    function _deleteFileObject(
        mapping (uint => File) storage _files,
        uint _ein,
        uint _fileIndex,
        mapping (uint => IceSort.SortOrder) storage _fileOrderMapping,
        mapping (uint => uint) storage _fileCountMapping,
        Group storage _fileGroup
    )
    internal {
        // Remove file from Group which holds the File
        removeFileFromGroup(
            _fileGroup, 
            _files[_fileIndex].associatedGroupFileIndex
        );

        // Swap File
        _files[_fileIndex] = _files[_fileCountMapping[_ein]];
        _fileCountMapping[_ein] = _fileOrderMapping.stichSortOrder(_fileIndex, _fileCountMapping[_ein], 0);
    }

    // 2. FILE TO GROUP FUNCTIONS 
    /**
     * @dev Private Function to add file to a group
     * @param self is the pointer to the relevant Group Struct (IceFMS Library) to which the file has to bee added
     * @param _groupIndex is the index of the group belonging to that user, 0 is reserved for root
     * @param _fileIndex is the index of the file belonging to that user
     * @return associatedGroupIndex is the group index of within the mapping of groups for the specific user
     * @return associatedGroupFileIndex is the index where the file is placed within that group in the specific user's FMS
     */
    function addFileToGroup(
        Group storage self, 
        uint _groupIndex, 
        uint _fileIndex
    )
    public
    returns (
        uint associatedGroupIndex, 
        uint associatedGroupFileIndex
    ) {
        // Add File to a group is just adding the index of that file
        uint currentIndex = self.groupFilesCount;
        self.groupFilesCount = self.groupFilesOrder.addToSortOrder(self.groupFilesOrder[0].prev, currentIndex, _fileIndex);

        // Map group index and group order index in file
        associatedGroupIndex = _groupIndex;
        associatedGroupFileIndex = self.groupFilesCount;
    }

    /**
     * @dev Function to remove file from a group
     * @param self is the pointer to the relevant Group Struct (IceFMS Library) which has the file in the primary user's FMS
     * @param _groupFileOrderIndex is the index of the file order within that group
     */
    function removeFileFromGroup(
        Group storage self, 
        uint _groupFileOrderIndex
    )
    public {
        uint maxIndex = self.groupFilesCount;
        uint pointerID = self.groupFilesOrder[maxIndex].pointerID;

        self.groupFilesCount = self.groupFilesOrder.stichSortOrder(_groupFileOrderIndex, maxIndex, pointerID);
    }

    /**
     * @dev Private Function to remap file from one group to another
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _existingFileIndex is the file index in the user's FMS files mapping
     * @param _oldGroup is the pointer to the old group where the file was present in the user's FMS
     * @param _newGroup is the pointer to the new group where the file will be moved in the user's FMS
     * @param _newGroupIndex is the index of the new group where file has to be moved
     * @return groupFileIndex is the index of the file stored in that relevant group of the primary user 
     */
    function remapFileToGroup(
        File storage self,
        uint _existingFileIndex,
        Group storage _oldGroup,
        Group storage _newGroup, 
        uint _newGroupIndex
    )
    public
    returns (uint groupFileIndex) {
        // Remove File from existing group
        removeFileFromGroup(_oldGroup, self.associatedGroupFileIndex);

        // Add File to new group
        (self.associatedGroupIndex, self.associatedGroupFileIndex) = addFileToGroup(_newGroup, _newGroupIndex, _existingFileIndex);
        
        // The file added has the asssociated group file index now
        groupFileIndex = self.associatedGroupFileIndex;
    }
    
    /**
     * @dev Function to check that a file has been marked for transfer
     */
    function condItemMarkedForTransfer(
        File storage self
    )
    public view {
        // Check if the group file exists or not
        require (
            (self.fileMeta.markedForTransfer == false),
            "File already marked for Transfer"
        );
    }
    
    /**
     * @dev Function to check that a file has been marked for transferee EIN
     * @param _transfereeEIN is the intended EIN for file transfer
     */
    function condMarkedForTransferee(
        File storage self, 
        uint _transfereeEIN
    )
    public view {
        // Check if the group file exists or not
        require (
            (self.transferEIN == _transfereeEIN),
            "File not marked for Transfers"
        );
    }

    /**
     * @dev Function to check that ID = 0 is not modified as it's reserved item
     * @param _index The index to check
     */
    function condNonReservedItem(uint _index)
    public pure {
        require (
            (_index > 0),
            "Reserved Item"
        );
    }
    
    // 3. GROUP FUNCTIONS
    /**
     * @dev Function to return group info
     * @param self is the pointer to the Group Struct (IceFMS Library) passed
     * @param _groupIndex the index of the group
     * @param _groupCount is the count of the number of groups for that specific user
     * @return index is the index of the group
     * @return name is the name associated with the group
     */
    function getGroup(
        Group storage self,
        uint _groupIndex,
        uint _groupCount
    )
    external view 
    returns (
        uint index, 
        string memory name
    ) {
        // Check constraints
        _groupIndex.condValidItem(_groupCount);
    
        // Logic flow
        index = _groupIndex;
    
        if (_groupIndex == 0) {
            name = "Root";
        }
        else {
            name = self.name;
        }
    }
    
    /**
     * @dev Function to create a new Group for the user
     * @param self is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _groupName is the name which should be given to the group
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _globalIndex1 is the initial first index of global items
     * @param _globalIndex2 is the initial second index of global items
     * @return newGlobalIndex1 is the new first index of global items
     * @return newGlobalIndex2 is the new second index of global items
     * @return nextGroupIndex is the new count of the group index after creating a group
     */
    function createGroup(
        mapping (uint => Group) storage self,
        uint _ein,
        string calldata _groupName,
        
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        uint _globalIndex1,
        uint _globalIndex2
    )
    external 
    returns (
        uint newGlobalIndex1,
        uint newGlobalIndex2,
        uint nextGroupIndex
    ) {
        // Logic
        (newGlobalIndex1, newGlobalIndex2, nextGroupIndex) = _createGroupInner(
           self, 
           _ein, 
           _groupName, 
           _groupOrderMapping, 
           _groupCountMapping, 
           _globalItems, 
           _globalIndex1, 
           _globalIndex2
        );
    }
    
    /**
     * @dev Private Function to facilitate in creating new Group for the user
     * @param groups is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _groupName is the name which should be given to the group
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _globalIndex1 is the initial first index of global items
     * @param _globalIndex2 is the initial second index of global items
     * @return newGlobalIndex1 is the new first index of global items
     * @return newGlobalIndex2 is the new second index of global items
     * @return nextGroupIndex is the new count of the group index after creating a group
     */
    function _createGroupInner(
        mapping (uint => Group) storage groups,
        uint _ein,
        string memory _groupName,
        
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        uint _globalIndex1,
        uint _globalIndex2
    )
    internal 
    returns (
        uint newGlobalIndex1,
        uint newGlobalIndex2,
        uint nextGroupIndex
    ) {
        
        // Reserve Global Index
        (newGlobalIndex1, newGlobalIndex2) = IceGlobal.reserveGlobalItemSlot(_globalIndex1, _globalIndex2);

        // Check if this is unitialized, if so, initialize it, reserved value of 0 is skipped as that's root
        nextGroupIndex = _groupCountMapping[_ein].add(1);
        
        // Add to Global Items as well
        _globalItems.addItemToGlobalItems(newGlobalIndex1, newGlobalIndex2, _ein, nextGroupIndex, false, false, 0);
        
        // Assign it to User (EIN)
        groups[nextGroupIndex] = IceFMS.Group(
            IceGlobal.GlobalRecord(newGlobalIndex1, newGlobalIndex2), // Add Record to struct
    
            _groupName, //name of Group
            0 // The group file count
        );

        // Add to Stitch Order & Increment index
        _groupCountMapping[_ein] = _groupOrderMapping.addToSortOrder(_groupOrderMapping[0].prev, _groupCountMapping[_ein], 0);

    }
    
    /**
     * @dev Function to rename an existing group for the user / ein
     * @param self is the pointer to the Group Struct (IceFMS Library) passed
     * @param _groupIndex the index of the group
     * @param _groupCount is the count of the number of groups for that specific user
     * @param _groupName describes the new name of the group
     */
    function renameGroup(
        Group storage self,
        uint _groupIndex, 
        uint _groupCount,
        string calldata _groupName
    )
    external {
        // Check Restrictions
        condNonReservedGroup(_groupIndex);
        _groupIndex.condValidItem(_groupCount);

        // Replace the group name
        self.name = _groupName;
    }
    
    /**
     * @dev Function to delete an existing group for the user / ein
     * @param self is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the user
     * @param _groupIndex describes the associated index of the group for the user / ein
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function deleteGroup(
        mapping (uint => Group) storage self,
        uint _ein,
        
        uint _groupIndex,
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external 
    returns (uint currentGroupIndex) {
        // Check Restrictions
        condGroupEmpty(self[_groupIndex]); // Check that Group contains no Files
        condNonReservedGroup(_groupIndex);
        _groupIndex.condValidItem(_groupCountMapping[_ein]);
        
        // Check if the group exists or not
        currentGroupIndex = _groupCountMapping[_ein];

        // Remove item from sharing of other users
        IceGlobal.Association storage globalItem = self[_groupIndex].rec.getGlobalItemViaRecord(_globalItems);
        _totalSharesMapping.removeAllShares(
            _ein,
            globalItem, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Deactivate from global record
        globalItem.deleteGlobalRecord();

        // Swap Index mapping & remap the latest group ID if this is not the last group
        self[_groupIndex] = self[currentGroupIndex];
        _groupCountMapping[_ein] = _groupOrderMapping.stichSortOrder(_groupIndex, currentGroupIndex, 0);

        // Delete the latest group now
        delete (self[currentGroupIndex]);
    }
    
    /**
     * @dev Function to check that Group Order is valid
     * @param self is the particular group in question
     */
    function condGroupEmpty(Group storage self)
    public view {
        require (
            (self.groupFilesCount == 0),
            "Group has Files"
        );
    }
    
    /**
     * @dev Function to check that index 0 is not modified as this is Reserved in the Group Struct (IceFMS Library) for root folder
     * @param _index The index to check
     */
    function condNonReservedGroup(uint _index)
    internal pure {
        require (
            (_index > 0),
            "Reserved Item"
        );
    }
    
    // 5. TRANSFER FUNCTIONS
    /**
     * @dev Function to check file transfer conditions before initiating a file transfer 
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the EIN which is transferring the file 
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where the file is stored with respect to the user who is transferring the file
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _totalGroupsMapping is the entire mapping of the groups of the Ice FMS
     * @param _blacklist is the entire mapping of the Blacklist for all users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _identityRegistry is the pointer to the ERC-1484 Identity Registry
     */
    function doInitiateFileTransferChecks(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN, 
        uint _fileIndex, 
        
        mapping (uint => uint) storage _fileCountMapping,
        mapping (uint => mapping(uint => Group)) storage _totalGroupsMapping,
        mapping (uint => mapping(uint => bool)) storage _blacklist,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        
        IdentityRegistryInterface _identityRegistry
    )
    external view {
        IceGlobal.condEINExists(_transfereeEIN, _identityRegistry); // Check Valid EIN
        IceGlobal.condUniqueEIN(_transfererEIN, _transfereeEIN); // Check EINs and Unique
        _fileIndex.condValidItem(_fileCountMapping[_transfererEIN]); // Check if the item exists
        self[_transfererEIN][_fileIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check if the File is not stamped
        condItemMarkedForTransfer(self[_transfererEIN][_fileIndex]); // Check if the File is not marked for transfer
        // Check if the Group is not stamped
        _totalGroupsMapping[_transfererEIN][self[_transfererEIN][_fileIndex].associatedGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem();
        _blacklist[_transfereeEIN].condNotInList(_transfererEIN); // Check if The transfee hasn't blacklisted the file owner
    }
    
    /**
     * @dev Function to do file transfer(Part 1) from previous (current) owner to new owner
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored
     * @param _totalFilesOrderMapping is the entire mapping of the files order of the Ice FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @return nextTransfereeIndex is the index number where the file is stored in the recipient user's File Struct mapping 
     */
    function doFileTransferPart1 (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN, 
        uint _fileIndex, 
        
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalFilesOrderMapping, 
        mapping (uint => uint) storage _fileCountMapping
    )
    external 
    returns (uint nextTransfereeIndex) {
        // Check Constraints
        IceGlobal.condCheckUnderflow(_fileCountMapping[_transfererEIN]);
        
        // Get Indexes
        uint currentTransfereeIndex = _fileCountMapping[_transfereeEIN];
        nextTransfereeIndex =  currentTransfereeIndex.add(1);

        // Transfer the file to the transferee & later Delete it for transferer
        self[_transfereeEIN][nextTransfereeIndex] = self[_transfererEIN][_fileIndex];

        // Change file properties and transfer history
        uint8 tc = self[_transfereeEIN][nextTransfereeIndex].fileMeta.transferCount.add(1);

        self[_transfereeEIN][nextTransfereeIndex].transferHistory[tc] = _transfereeEIN;
        self[_transfereeEIN][nextTransfereeIndex].fileMeta.markedForTransfer = false;
        self[_transfereeEIN][nextTransfereeIndex].fileMeta.transferCount = tc;

        // add to transferee sort order & Increment index
        _fileCountMapping[_transfereeEIN] = _totalFilesOrderMapping[_transfereeEIN].addToSortOrder(
            _totalFilesOrderMapping[_transfereeEIN][0].prev, 
            currentTransfereeIndex, 
            0
        );
    }
    
    /**
     * @dev Function to do file transfer(Part 2) from previous (current) owner to new owner
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored
     * @param _toRecipientGroup is the intended group of the recipient user where the file should go
     * @param _recipientGroupCount is the number of groups present in the recipient's user FMS system
     * @param _nextTransfereeIndex is the index number where the file is stored in the recipient user's File Struct mapping
     * @param _totalGroupsMapping is the entire mapping of all the groups in Ice FMS
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function doFileTransferPart2 (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN, 
        uint _fileIndex, 
        uint _toRecipientGroup,
        uint _recipientGroupCount,
        uint _nextTransfereeIndex,
        
        mapping (uint => mapping(uint => Group)) storage _totalGroupsMapping,
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Check Constraints
        _toRecipientGroup.condValidItem(_recipientGroupCount); // Check if the group exists
        
        // Add File to transferee group
        (self[_transfereeEIN][_nextTransfereeIndex].associatedGroupIndex, self[_transfereeEIN][_nextTransfereeIndex].associatedGroupFileIndex) = addFileToGroup(
            _totalGroupsMapping[_transfereeEIN][_toRecipientGroup], 
            _toRecipientGroup, 
            _nextTransfereeIndex
        );
        
        // Get global association
        IceGlobal.Association storage globalItem = self[_transfereeEIN][_fileIndex].rec.getGlobalItemViaRecord(_globalItems);

        // Update global file association
        globalItem.ownerInfo.EIN = _transfereeEIN;
        globalItem.ownerInfo.index = _nextTransfereeIndex;
    }
    
    /**
     * @dev Function to initiate requested file transfer in a permissioned manner
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transfers is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function doPermissionedFileTransfer(
        File storage self,
        uint _transfereeEIN,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfers,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        _initiatePermissionedFileTransfer (
            self,
            _transfereeEIN,
            
            _transfers,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to initiate requested file transfer
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transfers is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function _initiatePermissionedFileTransfer(
        File storage self,
        uint _transfereeEIN,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfers,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    internal {
        // Check constraints
        self.rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check Item is file
        IceGlobal.condCheckOverflow(_transferCountMapping[_transfereeEIN]); // Check for Transfer Overflow 
        
        // Map it to transferee mapping of transfers
        uint nextTransferIndex = _transferCountMapping[_transfereeEIN] + 1;

        // Mark the file for transfer
        self.fileMeta.markedForTransfer = true;
        self.transferEIN = _transfereeEIN;
        self.transferIndex = nextTransferIndex;

        // Create New Transfer
        _transfers[nextTransferIndex] = self.rec;

        // Update sort order and index
        _transferCountMapping[_transfereeEIN] = _transferOrderMapping.addToSortOrder(_transferOrderMapping[0].prev, _transferCountMapping[_transfereeEIN], 0);
    }
    
    /**
     * @dev Function to accept file transfer (part 1) from a user
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     */
    function acceptFileTransferPart1(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN,
        uint _fileIndex
    )
    external {
        // Check Restrictions
        condMarkedForTransferee(self[_transfererEIN][_fileIndex], _transfereeEIN); // Check if the file is marked for transfer to the recipient
        
        // Set file to normal so that transfer
        self[_transfererEIN][_fileIndex].fileMeta.markedForTransfer = false;
    }
    
    /**
     * @dev Function to accept file transfer (part 2) from a user
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transferSpecificIndex is the index of the transfer mapping of the recipient which contains transfer info for that file
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function acceptFileTransferPart2(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN,
        
        uint _transferSpecificIndex, 
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Finally remove the file from Tranferee Mapping
        removeFileFromTransfereeMapping(
            self,
            
            _transfereeEIN,
            _transferSpecificIndex,
            
            _transfersMapping,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Function to cancel file transfer inititated by the current owner and / or recipient
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function cancelFileTransfer(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN,
        uint _transfereeEIN,
        uint _fileIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Check constraints
        condMarkedForTransferee(self[_transfererEIN][_fileIndex], _transfereeEIN);
        
        // Logic
        _cancelFileTransfer(
            self,
        
            _transfererEIN,
            _transfereeEIN,
            _fileIndex,
            
            _transfersMapping,
            _transferOrderMapping, 
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to cancel file transfer inititated by the current owner or the recipient
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function _cancelFileTransfer (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN,
        uint _transfereeEIN,
        uint _fileIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    private {
        // Cancel file transfer
        self[_transfererEIN][_fileIndex].fileMeta.markedForTransfer = false;

        // Remove file from  transferee
        uint transferSpecificIndex = self[_transfererEIN][_fileIndex].transferIndex;
        removeFileFromTransfereeMapping(
            self,
            _transfereeEIN,
            transferSpecificIndex,
            
            _transfersMapping,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to remove file from Transfers mapping of Transferee after file is transferred to them
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the new owner EIN
     * @param _transferSpecificIndex is the index of the association mapping of transfers
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function removeFileFromTransfereeMapping(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN, 
        uint _transferSpecificIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    internal {
        // Check Restrictions
        _transfersMapping[_transferSpecificIndex].getGlobalItemViaRecord(_globalItems).condItemIsFile();
        
        // Retrive the swapped item record and change the transferIndex to remap correctly
        IceGlobal.Association memory item = _transfersMapping[_transferSpecificIndex].getGlobalItemViaRecord(_globalItems);

        // Get Cureent Transfer Index
        uint currentTransferIndex = _transferCountMapping[_transfereeEIN];

        require (
            (currentTransferIndex > 0),
            "Index Not Found"
        );

        // Remove the file from transferer, ie swap mapping and stich sort order
        _transfersMapping[_transferSpecificIndex] = _transfersMapping[currentTransferIndex];
        _transferCountMapping[_transfereeEIN] = _transferOrderMapping.stichSortOrder(_transferSpecificIndex, currentTransferIndex, 0);
 
        //Only File is supported
        self[item.ownerInfo.EIN][item.ownerInfo.index].transferIndex = _transferSpecificIndex;
    }
    
    // 6. STRING / BYTE CONVERSION
    /**
     * @dev Helper Function to convert string to bytes32 format
     * @param _source is the string which needs to be converted
     * @return result is the bytes32 representation of that string
     */
    function stringToBytes32(string memory _source) 
    public pure 
    returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        string memory tempSource = _source;
        
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(tempSource, 32))
        }
    }
    
    /**
     * @dev Helper Function to convert bytes32 to string format
     * @param _x is the bytes32 format which needs to be converted
     * @return result is the string representation of that bytes32 string
     */
    function bytes32ToString(bytes32 _x) 
    public pure 
    returns (string memory result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        
        result = string(bytesStringTrimmed);
    }
}