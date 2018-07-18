pragma solidity ^0.4.16;


contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
}


contract owned {
    function owned() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract PublicSaleManager is owned {

    mapping (address => bool) _whiteList;
    mapping (address => uint256) _bonus;

    address _tokenAddress = 0xAF815e887b039Fc06a8ddDcC7Ec4f57757616Cd2;
    address _deadAddress = 0x000000000000000000000000000000000000dead;
    uint256 _conversionRate = 0;
    uint256 _startTime = 0;
    uint256 _totalBonus = 0;

    function addWhitelist(address[] addressList) public onlyOwner {
        // Whitelist is managed manually and addresses are added in batch.
        for (uint i = 0; i < addressList.length; i++) {
            _whiteList[addressList[i]] = true;
        }
    }

    function start(uint32 conversionRate) public onlyOwner {
        require(_startTime == 0);
        require(_conversionRate > 1);

        // Starts the public sale.
        _startTime = now;

        // Sets the conversion rate.
        _conversionRate = conversionRate;
    }

    function burnUnsold() public onlyOwner {
        require(now >= _startTime + (31 days));

        // Transfers all un-sold tokens to 0x000...dead.
        ERC20(_tokenAddress).transfer(_deadAddress, ERC20(_tokenAddress).balanceOf(this) - _totalBonus);
    }

    function buyTokens() payable public {
        // Validates whitelist.
        require(_whiteList[msg.sender] == true);

        // Validates time.
        require(now > _startTime);
        require(now < _startTime + (31 days));

        // Calculates the purchase amount.
        uint256 purchaseAmount = msg.value * _conversionRate;
        require(_conversionRate > 0 && purchaseAmount / _conversionRate == msg.value);

        // Checks that we still have enough balance.
        require(ERC20(_tokenAddress).balanceOf(this) > _totalBonus);
        require(purchaseAmount <= ERC20(_tokenAddress).balanceOf(this) - _totalBonus);

        // Transfers the non-bonus part.
        ERC20(_tokenAddress).transfer(msg.sender, purchaseAmount);

        // Records the bonus part.
        if (now < _startTime + (6 hours)) {
            _bonus[msg.sender] += purchaseAmount / 10;
            _totalBonus += _bonus[msg.sender];
        } else if (now < _startTime + (24 hours)) {
            _bonus[msg.sender] += purchaseAmount / 20;
            _totalBonus += _bonus[msg.sender];
        }
    }

    function claimBonus() public {
        // Validates whitelist.
        require(_whiteList[msg.sender] == true);
        
        // Validates bonus.
        require(_bonus[msg.sender] > 0);

        // Transfers the bonus if it's after 90 days.
        if (now > _startTime + (90 days)) {
            ERC20(_tokenAddress).transfer(msg.sender, _bonus[msg.sender]);
        }
    }
}
