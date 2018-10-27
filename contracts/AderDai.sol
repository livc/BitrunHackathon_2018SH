pragma solidity ^0.4.25;

/**
 * @title AderDai Kovan 
 */

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
import "./DSToken.sol";

contract AderDai is DSToken {
    address constant private testAccount = 0x3fa17c1f1a0ae2db269f0b572ca44b15bc83929a;
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
    mapping (uint256 => AderDaidatasets.Bidder) public bidder_; // (bID => data) returns bidder info by bidder id
//****************
// GAME DATA 
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

//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================
    /**
     * @dev bid anyway
     */
    function()
        isHuman()
        priceLimited()
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

    /**
     * @dev logic runs whenever a buy order is executed. 
     */
    function buyCore(uint256 _bID, AderDaidatasets.EventReturns memory _eventData_)
        private
    {
        // transfer Dai to testAccount
        transfer(testAccount, msg.value);
        // update bidding price
        bidPrice_ = calcBidPrice();
        bidder_[_bID].owner = true;
        // if bidder more than 1, set bID-1 to false
        if (_bID > 1) {
            bidder_[_bID-1].owner = false;
        }
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
}

/**
* @title AderDai datasets
*/
library AderDaidatasets {
    struct Bidder {
        uint256 id;   // bidder id
        address addr; // bidder address
        uint256 gen;    // general vault
        bool owner;   // ad owner
    }
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
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