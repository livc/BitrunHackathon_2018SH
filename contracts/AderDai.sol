pragma solidity ^0.4.25;

/**
 * @title AderDai Kovan 
 */

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
library AderDaidatasets {
    struct Bidder {
        uint256 id;   // bidder id
        uint256 gen;    // general vault
        bool winner;   // bidder winner
    }
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        uint256 genAmount;          // amount distributed to gen
    }
}



contract AderDai {
    address constant private Dai = "0xc4375b7de8af5a38a93548eb8453a498222c4ff2";
//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    string constant public name = "AderDai";
    string constant public symbol = "AD";
    uint256 constant private initPrice_ = 100000000000000000000;
    uint256 constant private bidRate_ = 1100000000000000000;
//****************
// BIDDER DATA 
//****************
    mapping (address => uint256) public bIDxAddr_;          // (addr => bID) returns bidder id by address
    mapping (address => AderDaidatasets.Bidder) public bidder_; // (addr => data) returns bidder info by address
    uint256 public bidCount_;

//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor () 
        public
    {
        bidCount_ = 0;
    }

//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
//==============================================================================
    /**
     * @dev prevents contracts from interacting with AderDai 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================
    /**
     * @dev bid anyway
     */
    function()
        isHuman()
        public
        payable
    {
        // set up our tx event data
        AderDaidatasets.EventReturns memory _eventData_ = updateBID(_eventData_);
            
        // fetch bidder id
        uint256 _bID = bIDxAddr_[msg.sender];
        
        // buy core 
        buyCore(_bID, _eventData_);
    }

    function buyCore(uint256 _bID, AderDaidatasets.EventReturns memory _eventData_)
        private
    {
        // if bidding is active
        if (bidder_[msg.sender].winner != true)
        {

        }
        // if bidding is not active
        else 
        {

        }

    }

    /**
     * @dev update bID
     * @return bID 
     */
    function updateBID(AderDaidatasets.EventReturns memory _eventData_)
        private
        returns (AderDaidatasets.EventReturns)
    {
        bidCount_++;
        bIDxAddr_[msg.sender] = bidCount_;
        bidder_[msg.sender].id = bidCount_;
        
        // set the new player bool to true
        _eventData_.compressedData = _eventData_.compressedData + 1;
        return (_eventData_);
    }
}