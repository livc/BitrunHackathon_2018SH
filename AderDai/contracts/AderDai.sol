pragma solidity ^0.4.24;

/**
 * @title AderDai Kovan 
 */

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

////// lib/ds-stop/lib/ds-auth/src/auth.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.13; */

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// lib/ds-stop/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.13; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

////// lib/ds-stop/src/stop.sol
/// stop.sol -- mixin for enable/disable functionality

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.13; */

/* import "ds-auth/auth.sol"; */
/* import "ds-note/note.sol"; */

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

////// lib/erc20/src/erc20.sol
/// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

/* pragma solidity ^0.4.8; */

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

////// src/base.sol
/// base.sol -- basic ERC20 implementation

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.13; */

/* import "erc20/erc20.sol"; */
/* import "ds-math/math.sol"; */

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function DSTokenBase(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        Approval(msg.sender, guy, wad);

        return true;
    }
}

////// src/token.sol
/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.13; */

/* import "ds-stop/stop.sol"; */

/* import "./base.sol"; */

contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize

    function DSToken(bytes32 symbol_) public {
        symbol = symbol_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        Burn(guy, wad);
    }

    // Optional token name
    bytes32   public  name = "";

    function setName(bytes32 name_) public auth {
        name = name_;
    }
}


















contract AderDai is DSToken {
    using SafeMath for *;

    address constant private testAccount = 0x3fa17c1f1a0ae2db269f0b572ca44b15bc83929a;
    address constant private teamAccount = 0x89428305344Fe5De0801EDF41C5632C1e0FA231C;
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
    uint256 constant private teamInterest_ = uint256(20 / 100);
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
            transferFrom(address(this), bidder_[_bID].addr, _divide);
            bidder_[_bID].frzValue.sub(_divide);
            // reset date
            bidder_[_bID].date = now;
        }
    }

    /**
     * @dev give interest to team
     */
    function iTeam(uint256 _bID)
        public
        payable
    {        
        // calculate interest
        uint256 _interest = ((bidder_[_bID].frzValue).div(1 + teamInterest_)).mul(teamInterest_);
        // give it to team
        transferFrom(address(this), teamAccount, _interest);
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
        // if bidder more than 1, set bID-1 to false and do gen share.
        if (_bID > 1) {
            bidder_[_bID-1].owner = false;
            bidder_[_bID-1].frzValue.add(msg.value);
            bidder_[_bID-1].gen.add(msg.value);
            bidder_[_bID].frzValue.sub(msg.value);
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