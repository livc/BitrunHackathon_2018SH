pragma solidity ^0.4.24;

/**
 * @title AderDai Kovan 
 */

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
import "./DSToken.sol";

contract AderDai is DSToken {
    using SafeMath for *;

    address constant private testAccount = 0x3fa17c1f1a0ae2db269f0b572ca44b15bc83929a;
//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (bid settings)
//=================_|===========================================================
    string constant public name = "AderDai";
    string constant public symbol = "AD";
    uint256 constant private initPrice_ = 100000000000000000000;
    uint256 constant private bidRate_ = 1100000000000000000;
    uint256 constant private interestPeriod_ = 31 days;
    uint256 constant private returnPeriod_ = 12;
    uint256 constant private teamInterest_ = 0.2;
//****************
// BIDDER DATA 
//****************
    mapping (address => uint256) public bIDxAddr_;          // (addr => bID) returns bidder id by address
    mapping (uint256 => AderDaidatasets.Bidder) public bidder_; // (bID => data) returns bidder info by bidder id
//****************
// BIDDING DATA 
//****************
    uint256 public bidCount_;
    uint256 public bidPrice_;

//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor () 
        public
    {
        bidCount_ = 0;
        bidPrice_ = initPrice_;
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

    /**
     * @dev sets the price to limited price
     */
    modifier priceLimited() {
        require(msg.value == bidPrice_, "sorry limited price");
        _;
    }

    /**
     * @dev sets the per date period to 31 days
     */
    modifier dateLimited(uint256 _bID) {
        require(now.sub(bidder_[_bID].date) > interestPeriod_, "date does not meets");
        _;
    }

//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================
    /**
     * @dev bid with url
     */
    function uBid(string _url)
        isHuman()
        priceLimited()
        public
        payable
    {
        // set up our tx event data
        AderDaidatasets.EventReturns memory _eventData_ = updateBID(_eventData_);
            
        // fetch bidder id
        uint256 _bID = bIDxAddr_[msg.sender];

        // update url
        bidder_[_bID].url = _url;
        
        // bid core 
        bidCore(_bID, _eventData_);
    }

    /**
     * @dev return with interest
     */
    function iReturn(uint256 _bID)
        dateLimited(_bID)
        public
        payable
    {        
        // divide to 12 period
        uint256 _divide = bidder_[_bID].frzValue.div(returnPeriod_);

        if ( bidder_[_bID].frzValue >= _divide ) {
            bidder_[_bID].addr.transfer(_divide);
            bidder_[_bID].frzValue.sub(_divide);
            // reset date
            bidder_[_bID].date = now;
        }
    }



    /**
     * @dev logic runs whenever a bid order is executed. 
     */
    function bidCore(uint256 _bID, AderDaidatasets.EventReturns memory _eventData_)
        private
        returns (AderDaidatasets.EventReturns)
    {
        // setting bidder data
        bidder_[_bID].owner = true;
        bidder_[_bID].date = now;
        bidder_[_bID].frzValue = msg.value;
        // if bidder more than 1, set bID-1 to false
        if (_bID > 1) {
            bidder_[_bID-1].owner = false;
        }
        // transfer Dai to testAccount
        transfer(testAccount, msg.value);
        // update bidding price
        bidPrice_ = calcBidPrice();

        // build event data
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _bID;
        _eventData_.ownerAddr = msg.sender;
    }

    /**
     * @dev request badding price.
     */
    function getBidPrice()
        public
        view
        returns(uint256)
    {
        return (bidPrice_);
    }

    /**
     * @dev calculate badding price.
     */
    function calcBidPrice()
        private
        view
        returns(uint256)
    {
        return (bidPrice_.mul(bidRate_));
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
        bidder_[bidCount_].id = bidCount_;
        bidder_[bidCount_].addr = msg.sender;
        
        // set the new player bool to true
        _eventData_.compressedData = _eventData_.compressedData + 1;
        return (_eventData_);
    }

    /**
     * @dev returns bidder sum. 
     * @return bidder sum
     */
    function getTotalBidder()
        public 
        view 
        returns(uint256)
    {
        return
        (
            bidCount_                               //0
        );
    }

    /**
     * @dev returns bidder id based on address. 
     * @param _addr address of the bidder you want to lookup 
     * @return bidder ID
     */
    function getBidderIdByAddress(address _addr)
        public 
        view 
        returns(uint256)
    {
        uint256 _bID = bIDxAddr_[_addr];

        return
        (
            _bID                               //0
        );
    }

    /**
     * @dev returns bidder info based on id. 
     * @param _bID id of the bidder you want to lookup 
     * @return bidder ID 
     * @return bidder address
     * @return date bided
     * @return value transferred
     * @return bid url
     * @return general vault 
	 * @return ad owned
     */
    function getBidderInfoById(uint256 _bID)
        public 
        view 
        returns(uint256, address, uint256, uint256, string, uint256, bool)
    {
        return
        (
            _bID,                               //0
            bidder_[_bID].addr,                 //1
            bidder_[_bID].date,                 //2
            bidder_[_bID].frzValue,             //3
            bidder_[_bID].url,                  //4
            bidder_[_bID].gen,                  //5
            bidder_[_bID].owner                 //6
        );
    }
}

/**
* @title AderDai datasets
*/
library AderDaidatasets {
    struct Bidder {
        uint256 id;   // bidder id
        address addr; // bidder address
        uint256 date; // bid date
        uint256 frzValue; // bid frzee value
        string url; // bid url
        uint256 gen;    // general vault
        bool owner;   // ad owner
    }
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address ownerAddr;         // owner address
        uint256 genAmount;          // amount distributed to gen
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}