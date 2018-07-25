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

    mapping (address => bool) _earlyList;
    mapping (address => bool) _whiteList;
    mapping (address => uint256) _bonus;
    mapping (address => uint256) _contributedETH;

    address _tokenAddress = 0xAF815e887b039Fc06a8ddDcC7Ec4f57757616Cd2;
    address _deadAddress = 0x000000000000000000000000000000000000dead;
    uint256 _conversionRate = 0;
    uint256 _startTime = 0;

    uint256 _totalSold = 0;
    uint256 _totalBonus = 0;

    uint256 _regularPersonalCap = 1e20; // 100 ETH
    uint256 _higherPersonalCap = 2e20; // 200 ETH
    uint256 _minimumAmount = 2e17; // 0.2 ETH

    bool _is_stopped = false;

    function addWhitelist(address[] addressList) public onlyOwner {
        // Whitelist is managed manually and addresses are added in batch.
        for (uint i = 0; i < addressList.length; i++) {
            _whiteList[addressList[i]] = true;
        }
    }
    
    function addEarlylist(address[] addressList) public onlyOwner {
        // Whitelist is managed manually and addresses are added in batch.
        for (uint i = 0; i < addressList.length; i++) {
            _earlyList[addressList[i]] = true;
        }
    }

    function start(uint32 conversionRate) public onlyOwner {
        require(_startTime == 0);
        require(conversionRate > 1);

        // Starts the public sale.
        _startTime = now;

        // Sets the conversion rate.
        _conversionRate = conversionRate;
    }

    function stop() public onlyOwner {
        _is_stopped = true;
    }

    function burnUnsold() public onlyOwner {
        require(now >= _startTime + (31 days));

        // Transfers all un-sold tokens to 0x000...dead.
        ERC20(_tokenAddress).transfer(_deadAddress, ERC20(_tokenAddress).balanceOf(this) - _totalBonus);
    }

    function withdrawEther(address toAddress, uint256 amount) public onlyOwner {
        toAddress.transfer(amount);
    }

    function buyTokens() payable public {
        require(_is_stopped == false);

        // Validates whitelist.
        require(_whiteList[msg.sender] == true || _earlyList[msg.sender] == true);

        if (_earlyList[msg.sender]) {
            require(msg.value + _contributedETH[msg.sender] <= _higherPersonalCap);
        } else {
            require(msg.value + _contributedETH[msg.sender] <= _regularPersonalCap);
        }

        require(msg.value >= _minimumAmount);

        // Validates time.
        require(now > _startTime);
        require(now < _startTime + (31 days));

        // Calculates the purchase amount.
        uint256 purchaseAmount = msg.value * _conversionRate;
        require(_conversionRate > 0 && purchaseAmount / _conversionRate == msg.value);

        // Calculates the bonus amount.
        uint256 bonus = 0;
        if (_totalSold + purchaseAmount < 5e26) {
            // 10% bonus for the first 500 million OGT.
            bonus = purchaseAmount / 10;
        } else if (_totalSold + purchaseAmount < 10e26) {
            // 5% bonus for the first 1 billion OGT.
            bonus = purchaseAmount / 20;
        }

        // Checks that we still have enough balance.
        require(ERC20(_tokenAddress).balanceOf(this) >= _totalBonus + purchaseAmount + bonus);

        // Transfers the non-bonus part.
        ERC20(_tokenAddress).transfer(msg.sender, purchaseAmount);
        _contributedETH[msg.sender] += msg.value;

        // Records the bonus.
        _bonus[msg.sender] += bonus;

        _totalBonus += bonus;
        _totalSold += (purchaseAmount + bonus);
    }

    function claimBonus() public {
        // Validates whitelist.
        require(_whiteList[msg.sender] == true || _earlyList[msg.sender] == true);
        
        // Validates bonus.
        require(_bonus[msg.sender] > 0);

        // Transfers the bonus if it's after 90 days.
        if (now > _startTime + (90 days)) {
            ERC20(_tokenAddress).transfer(msg.sender, _bonus[msg.sender]);
            _bonus[msg.sender] = 0;
        }
    }

    function checkBonus(address purchaser) public constant returns (uint256 balance) {
        return _bonus[purchaser];
    }

    function checkTotalSold() public constant returns (uint256 balance) {
        return _totalSold;
    }

    function checkContributedETH(address purchaser) public constant returns (uint256 balance) {
        return _contributedETH[purchaser];
    }

    function checkPersonalRemaining(address purchaser) public constant returns (uint256 balance) {
        if (_earlyList[purchaser]) {
            return _higherPersonalCap - _contributedETH[purchaser];
        } else if (_whiteList[purchaser]) {
            return _regularPersonalCap - _contributedETH[purchaser];
        } else {
            return 0;
        }
    }
}


contract TeamTokenLock is owned {

    address _tokenAddress = 0xAF815e887b039Fc06a8ddDcC7Ec4f57757616Cd2;
    uint256 _startTime = 1534723200;  // Aug 20, 2018
    uint256 _totalWithdrawAmount = 0;

    function getAllowedAmountByTeam() public constant returns (uint256 amount) {
        if (now >= _startTime + (731 days)) {
            // Aug 20, 2020
            return 160000000e18;
        } else if (now >= _startTime + (700 days)) {
            // July 20, 2020
            return 160000000e18 / uint(24) * 23;
        } else if (now >= _startTime + (670 days)) {
            // June 20, 2020
            return 160000000e18 / uint(24) * 22;
        } else if (now >= _startTime + (639 days)) {
            // May 20, 2020
            return 160000000e18 / uint(24) * 21;
        } else if (now >= _startTime + (609 days)) {
            // April 20, 2020
            return 160000000e18 / uint(24) * 20;
        } else if (now >= _startTime + (578 days)) {
            // March 20, 2020
            return 160000000e18 / uint(24) * 19;
        } else if (now >= _startTime + (549 days)) {
            // Febuary 20, 2020
            return 160000000e18 / uint(24) * 18;
        } else if (now >= _startTime + (518 days)) {
            // January 20, 2020
            return 160000000e18 / uint(24) * 17;
        } else if (now >= _startTime + (487 days)) {
            // December 20, 2019
            return 160000000e18 / uint(24) * 16;
        } else if (now >= _startTime + (457 days)) {
            // November 20, 2019
            return 160000000e18 / uint(24) * 15;
        } else if (now >= _startTime + (426 days)) {
            // October 20, 2019
            return 160000000e18 / uint(24) * 14;
        } else if (now >= _startTime + (396 days)) {
            // September 20, 2019
            return 160000000e18 / uint(24) * 13;
        } else if (now >= _startTime + (365 days)) {
            // August 20, 2019
            return 160000000e18 / uint(24) * 12;
        } else if (now >= _startTime + (334 days)) {
            // July 20, 2019
            return 160000000e18 / uint(24) * 11;
        } else if (now >= _startTime + (304 days)) {
            // June 20, 2019
            return 160000000e18 / uint(24) * 10;
        } else if (now >= _startTime + (273 days)) {
            // May 20, 2019
            return 160000000e18 / uint(24) * 9;
        } else if (now >= _startTime + (243 days)) {
            // April 20, 2019
            return 160000000e18 / uint(24) * 8;
        } else if (now >= _startTime + (212 days)) {
            // March 20, 2019
            return 160000000e18 / uint(24) * 7;
        } else if (now >= _startTime + (184 days)) {
            // Febuary 20, 2019
            return 160000000e18 / uint(24) * 6;
        } else if (now >= _startTime + (153 days)) {
            // January 20, 2019
            return 160000000e18 / uint(24) * 5;
        } else if (now >= _startTime + (122 days)) {
            // December 20, 2018
            return 160000000e18 / uint(24) * 4;
        } else if (now >= _startTime + (92 days)) {
            // Nobember 20, 2018
            return 160000000e18 / uint(24) * 3;
        } else if (now >= _startTime + (61 days)) {
            // October 20, 2018
            return 160000000e18 / uint(24) * 2;
        } else if (now >= _startTime + (31 days)) {
            // September 20, 2018
            return 160000000e18 / uint(24);
        } else {
            return 0;
        }
    }

    function withdrawByTeam(address toAddress, uint256 amount) public onlyOwner {
        require(now >= _startTime);

        uint256 allowedAmount = getAllowedAmountByTeam();

        require(amount + _totalWithdrawAmount < allowedAmount);

        _totalWithdrawAmount += amount;

        ERC20(_tokenAddress).transfer(toAddress, amount);
    }

    function withdrawByFoundation(address toAddress, uint256 amount) public onlyOwner {
        require(now >= _startTime + (731 days));

        ERC20(_tokenAddress).transfer(toAddress, amount);
    }
}
