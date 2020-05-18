pragma solidity ^0.5.1;

import "./SafeMath.sol";

/**
 * @title Ice Protocol Sort Libray
 * @author Harsh Rajat
 * @notice Create sorting order for maximizing space utilization
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceSort {
     using SafeMath for uint;
     
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    /* To define the order required to have double linked list */
    struct SortOrder {
        uint next; // the next ID of the order
        uint prev; // the prev ID of the order

        uint pointerID; // what it should point to in the mapping

        bool active; // whether the node is active or not
    }
    
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. SORTING LIBRARY
    /**
     * @dev Function to facilitate returning of double linked list used
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     * @return prev is the previous index in the sort order mapping 
     * @return next is the next index in the sort order mapping
     * @return pointerID is the pointer index which the sort order is pointing to
     * @return active shows whether that particular sort order mapping is active or not
     */
    function getOrder(
        mapping(uint => SortOrder) storage self, 
        uint _seedPointer
    )
    public view
    returns (uint prev, uint next, uint pointerID, bool active) {
        prev = self[_seedPointer].prev;
        next = self[_seedPointer].next;
        pointerID = self[_seedPointer].pointerID;
        active = self[_seedPointer].active;
    }

    /**
     * @dev Function to facilitate adding of double linked list used to preserve order and form cicular linked list
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _currentIndex is the index which is at the last of the queue
     * @param _maxIndex is the highest index present
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     * @return nextIndex is the count of the specific sort order mapping
     */
    function addToSortOrder(
        mapping(uint => SortOrder) storage self, 
        uint _currentIndex,
        uint _maxIndex,
        uint _pointerID
    )
    external
    returns (uint nextIndex) {
        // Next Index is always +1
        nextIndex = _maxIndex.add(1);

        // Assign current order to next pointer
        self[_currentIndex].next = nextIndex;
        self[_currentIndex].active = true;

        // Special case of root of sort order
        if (_maxIndex == 0) {
            self[0].next = nextIndex;
        }

        // Assign initial group prev order
        self[0].prev = nextIndex;

        // Whether This is assigned or calculated
        uint pointerID;
        if (_pointerID == 0) {
            pointerID = nextIndex;
        }
        else {
            pointerID = _pointerID;
        }

        // Assign next group order pointer and prev pointer
        self[nextIndex] = SortOrder(
            0, // next index
            _currentIndex, // prev index
            pointerID, // pointerID
            true // mark as active
        );
    }

    /**
     * @dev Function to facilitate stiching of double linked list used to preserve order with delete
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _remappedIndex is the index which is swapped to from the latest index
     * @param _maxIndex is the index which will always be maximum
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     * @return prevIndex is the count of the specific sort order mapping
     */
    function stichSortOrder(
        mapping(uint => SortOrder) storage self, 
        uint _remappedIndex, 
        uint _maxIndex, 
        uint _pointerID
    )
    external
    returns (uint prevIndex){
        // Stich Order
        uint prevGroupIndex = self[_remappedIndex].prev;
        uint nextGroupIndex = self[_remappedIndex].next;

        self[prevGroupIndex].next = nextGroupIndex;
        self[nextGroupIndex].prev = prevGroupIndex;

        // Check if this is not the top order number
        if (_remappedIndex != _maxIndex) {
            // Change order mapping and remap
            self[_remappedIndex] = self[_maxIndex];
            if (_pointerID == 0) {
                self[_remappedIndex].pointerID = _remappedIndex;
            }
            else {
                self[_remappedIndex].pointerID = _pointerID;
            }
            self[self[_remappedIndex].next].prev = _remappedIndex;
            self[self[_remappedIndex].prev].next = _remappedIndex;
        }

        // Turn off the non-stich group
        self[_maxIndex].active = false;

        // Decrement count index if it's non-zero
        prevIndex = _maxIndex.sub(1);
    }
    
    // *. REFERENTIAL INDEXES FUNCTIONS
    /**
     * @dev Private Function to return maximum 20 Indexes of Files, Groups, Transfers,
     * etc based on their SortOrder. 0 is always reserved but will point to Root in Group & Avatar in Files
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     * @param _limit is the number of files requested | Maximum of 20 can be retrieved
     * @param _asc is the order, i.e. Ascending or Descending
     * @return sortedIndexes is the indexes returned for Files, Groups, Transfers, etc
     */
    function getIndexes(
        mapping(uint => SortOrder) storage self, 
        uint _seedPointer, 
        uint16 _limit, 
        bool _asc
    )
    external view
    returns (uint[20] memory sortedIndexes) {
        uint next;
        uint prev;
        uint pointerID;
        bool active;
        
        uint limit = _limit;
        
        // Get initial Order
        (prev, next, pointerID, active) = getOrder(self, _seedPointer);

        // Get Previous or Next Order | Round Robin Fashion
        if (_asc == true) {
            // Ascending Order
            (prev, next, pointerID, active) = getOrder(self, next);
        }
        else {
            // Descending Order
            (prev, next, pointerID, active) = getOrder(self, prev);
        }

        uint16 i = 0;

        if (limit >= 20) {
            limit = 20; // always account for root
        }

        while (limit != 0) {

            if (active == false || pointerID == 0) {
                limit = 0;

                if (pointerID == 0) {
                    //add root as Special case
                    sortedIndexes[i] = 0;
                }
            }
            else {
                // Get PointerID
                sortedIndexes[i] = pointerID;

                // Get Previous or Next Order | Round Robin Fashion
                if (_asc == true) {
                    // Ascending Order
                    (prev, next, pointerID, active) = getOrder(self, next);
                }
                else {
                    // Descending Order
                    (prev, next, pointerID, active) = getOrder(self, prev);
                }

                // Increment counter
                i++;

                // Decrease Limit
                limit--;
            }
        }
    }
    
    /**
     * @dev Function to check that Group Order is valid
     * @param self is the specific SortOrder Struct (IceSort Library)
     * @param _groupOrderIndex The index of the group order
     */
    function condValidSortOrder(
        SortOrder storage self, 
        uint _groupOrderIndex
    )
    public view {
        require (
            (_groupOrderIndex == 0 || self.active == true),
            "Group Order not Found"
        );
    }
}