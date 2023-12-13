// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Ownable {
    // Variable that maintains
    // owner address
    address private _owner;

    // Sets the original owner of
    // contract when it is deployed
    constructor() {
        _owner = msg.sender;
    }

    // Publicly exposes who is the
    // owner of this contract
    function owner() public view returns (address) {
        return _owner;
    }

    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not
    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function transferOwnership(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Invalid Address");
        _owner = newAddress;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

contract BobMiner is Ownable {
    uint256 public totalLevels = 11;
    uint256 public annualROI = 3;
    uint256 public directCommissionRate = 50;
    uint256 public level1CommissionRate = 50;
    uint256 public divisionFactor = 1000;
    uint256 public blocksInADay = 28800;
    address public developerAddress = 0x00847ef42200ebeecb13cF86B76A074f86d91f4c;
    uint256 public totalWithdrawals = 0 ether;
    uint256 public totalInvested = 0 ether;
    uint256 public profitMultiplier = 5;
    uint256 public launchTimestamp;
    bool public init = false;

   event Deposit(address index, address ref, uint256 amount);
   event WithdrawROI(address index, uint256 amount);
   event WithdrawRef(address index,uint256 amount);

    struct LevelUnlock {
        address _addr;
        uint256 level;
    }

    struct deposit_status {
        address _addr;
        uint256 investment;
        uint256 block_id;
        bool status;
    }
    struct userWithdraw {
        address _addr;
        uint256 totalWithdraw;
    }

    struct ref_tree {
        address _addr;
        uint256 _key;
        address _refered;
    }

    struct refCount {
        address _addr;
        uint256 DirectRef;
        uint256 SubRef;
    }

    struct ref_withdraw {
        address _addr;
        uint256 total_withdrawn;
    }

    struct perRefReward {
        address _addr;
        uint256 level;
        uint256 amount;
        uint256 total_users;
        uint256 block_id;
    }

    struct DirectROIReward {
        address _addr;
        uint256 earned;
    }

    struct DirectRecord {
        address _addr;
        bool init;
    }

    struct Record5x {
        address _addr;
        bool init;
    }

    mapping(address => mapping(uint256 => ref_tree)) public RefCount;
    mapping(address => mapping(uint256 => perRefReward)) public RefRewards;
    mapping(address => ref_withdraw) public withdrawn;
    mapping(address => deposit_status) public depositQuery;
    mapping(address => LevelUnlock) public Level;
    mapping(address => refCount) public counter;
    mapping(address => userWithdraw) public ROI_WITHDRAW;
    mapping(address => DirectROIReward) public ROIREWARD;
    mapping(address => DirectRecord) public Record;
    mapping(address => Record5x) public withdrawInit;

    function DEPOSIT(address ref) public payable {
        require(
            msg.value >= 0.05 ether,
            "You cannot deposit less than 0.05 amount of BNB"
        );
        require(launchTimestamp != 0);
        if (withdrawInit[msg.sender].init) {
            withdrawInit[msg.sender].init = false;
        }

        totalInvested = totalInvested + msg.value;

        withdrawn[msg.sender]._addr = msg.sender;
        Level[msg.sender]._addr = msg.sender;
        ROI_WITHDRAW[msg.sender]._addr = msg.sender;

        if (Level[ref]._addr != address(0)) {
            if (totalLevels >= Level[ref].level) {
                if (Record[ref].init) {
                    Level[ref].level = Level[ref].level + 1;
                } else {
                    Record[ref].init = true;
                }
            }
        }

        counter[msg.sender]._addr = msg.sender;

        counter[ref].DirectRef = counter[ref].DirectRef + 1;

        require(ref != address(0) && ref != msg.sender);
        uint256 refFee_ = RefFee(msg.value);
        uint256 dev_fee = DevFee(msg.value);

        payable(developerAddress).transfer(dev_fee);
        payable(ref).transfer(refFee_);

        uint256 totalGetRef = ROIREWARD[ref].earned;
        uint256 totalAddPlus = totalGetRef + refFee_;
        ROIREWARD[ref] = DirectROIReward(ref, totalAddPlus);

        withdrawn[msg.sender]._addr = msg.sender;

        if (!depositQuery[msg.sender].status) {
            for (uint256 i = 0; i <= 11; i++) {
                if (i == 0) {
                    RefCount[msg.sender][i] = ref_tree(msg.sender, i, ref);
                    if (!init) {
                        uint256 _userROI = (msg.value * 100) * annualROI;
                        _userROI = _userROI * msg.value * annualROI;
                        uint256 _amountRef = FeeViewer(_userROI, i);
                        RefRewards[ref][i].total_users++;
                        uint256 upToDateAmount = RefRewards[ref][i].amount +
                            _amountRef;

                        RefRewards[ref][i].amount = upToDateAmount;
                        if (RefRewards[ref][i].block_id == 0) {
                            RefRewards[ref][i].block_id = block.number;
                        }
                    } else {
                        uint256 _userROI = (msg.value / 100) * annualROI;
                        uint256 _amountRef = FeeViewer(_userROI, i);
                        RefRewards[ref][i].total_users++;
                        uint256 upToDateAmount = RefRewards[ref][i].amount +
                            _amountRef;

                        RefRewards[ref][i].amount = upToDateAmount;
                        if (RefRewards[ref][i].block_id == 0) {
                            RefRewards[ref][i].block_id = block.number;
                        }
                    }
                } else {
                    ref = RefCount[ref][0]._refered;
                    if (ref != address(0) && Level[ref].level >= i) {
                        RefCount[msg.sender][i] = ref_tree(msg.sender, i, ref);
                        counter[ref].SubRef = counter[ref].SubRef + 1;
                        uint256 _userROI = (msg.value / 100) * 1;
                        uint256 _amountRef = FeeViewer(_userROI, i);
                        RefRewards[ref][i].total_users++;

                        uint256 upToDateAmount = RefRewards[ref][i].amount +
                            _amountRef;
                        RefRewards[ref][i].level = i;
                        RefRewards[ref][i].amount = upToDateAmount;
                        if (RefRewards[ref][i].block_id == 0) {
                            RefRewards[ref][i].block_id = block.number;
                        }
                    }
                }
            }
        }

        if (!depositQuery[msg.sender].status) {
            depositQuery[msg.sender]._addr = msg.sender;
            depositQuery[msg.sender].investment =
                depositQuery[msg.sender].investment +
                msg.value;
            depositQuery[msg.sender].block_id = block.number;
            depositQuery[msg.sender].status = true;
        } else {
            depositQuery[msg.sender].investment =
                depositQuery[msg.sender].investment +
                msg.value;
        }

        emit Deposit(msg.sender, ref, msg.value);
    }

    function InjectFunds() public payable onlyOwner {}

    function FeeViewer(uint256 amount, uint256 _position)
        public
        pure
        returns (uint256)
    {
        if (_position == 0) {
            uint256 total = (amount / 100) * 9;
            return total;
        } else if (_position == 1) {
            uint256 total = (amount / 100) * 6;
            return total;
        } else if (_position == 2) {
            uint256 total = (amount / 100) * 3;
            return total;
        } else if (_position == 3) {
            uint256 total = (amount / 100) * 3;
            return total;
        } else if (_position == 4) {
            uint256 total = (amount / 100) * 3;
            return total;
        } else if (_position == 5) {
            uint256 total = (amount / 100) * 2;
            return total;
        } else if (_position == 6) {
            uint256 total = (amount / 100) * 2;
            return total;
        } else if (_position == 7) {
            uint256 total = (amount / 100) * 2;
            return total;
        } else if (_position == 8) {
            uint256 total = (amount / 100) * 4;
            return total;
        } else if (_position == 9) {
            uint256 total = (amount / 100) * 4;
            return total;
        } else if (_position == 10) {
            uint256 total = (amount / 100) * 5;
            return total;
        } else if (_position == 11) {
            uint256 total = (amount / 100) * 7;
            return total;
        } else {
            return 0;
        }
    }

    function withdrawROI() public {
        require(
            !withdrawInit[msg.sender].init,
            "You have exceed the amount to withdraw"
        );
        require(init);
        deposit_status storage userStatus = depositQuery[msg.sender];
        userWithdraw storage userWithdrawX = ROI_WITHDRAW[msg.sender];
        uint256 totalWithdraw = DailyROI(msg.sender);
        uint256 totalBalanceNOW = address(this).balance;
        if (totalWithdraw <= totalBalanceNOW) {
            uint256 devFee_ = DevFee(totalWithdraw);

            uint256 totalFee = devFee_;
            uint256 totalValue = totalWithdraw - totalFee;
            payable(developerAddress).transfer(devFee_);
            payable(msg.sender).transfer(totalValue);

            totalWithdrawals = totalWithdraw + totalWithdrawals;
            userStatus.block_id = block.number;

            userWithdrawX.totalWithdraw =
                userWithdrawX.totalWithdraw +
                totalWithdraw;

            if (
                userWithdrawX.totalWithdraw +
                    withdrawn[msg.sender].total_withdrawn >=
                userStatus.investment * profitMultiplier
            ) {
                withdrawInit[msg.sender] = Record5x(msg.sender, true);
            }
        } else {
            payable(msg.sender).transfer(totalBalanceNOW);
        }
        emit WithdrawROI(msg.sender, totalWithdraw);
    }

    function DailyROI(address _addr) public view returns (uint256) {
        deposit_status storage userDeposit = depositQuery[_addr];
        uint256 blockID = userDeposit.block_id;
        uint256 userCapital = (userDeposit.investment / 100) * annualROI;

        uint256 perBlock = userCapital / blocksInADay;

        uint256 CurrentID = block.number;
        uint256 total = CurrentID - blockID;
        return total * perBlock;
    }

    function RefDailyROI(address _addr, uint256 _position)
        public
        view
        returns (uint256)
    {
        perRefReward storage ReferralStatus = RefRewards[_addr][_position];
        uint256 blockID = ReferralStatus.block_id;
        uint256 userCapital = ReferralStatus.amount;
        uint256 perBlock = userCapital / blocksInADay;
        uint256 CurrentID = block.number;
        uint256 total = CurrentID - blockID;
        return total * perBlock;
    }

    function ReInvest() public {
        uint256 _value = DailyRefROIReward(msg.sender);
        depositQuery[msg.sender].investment =
            depositQuery[msg.sender].investment +
            _value;
        depositQuery[msg.sender].block_id = block.number;
    }

    function LevelTotal(address _addr, uint256 _position)
        public
        view
        returns (uint256)
    {
        perRefReward storage ReferralStatus = RefRewards[_addr][_position];
        return ReferralStatus.amount;
    }

    function LevelTotalAmount(address _addr) public view returns (uint256) {
        uint256 _total = 0;
        for (uint256 i = 0; i <= 11; i++) {
            uint256 total = LevelTotal(_addr, i);
            _total = total + _total;
        }
        return _total;
    }

    function DailyRefROIReward(address _addr) public view returns (uint256) {
        uint256 _total = 0;
        for (uint256 i = 0; i <= 11; i++) {
            uint256 total = RefDailyROI(_addr, i);
            _total = total + _total;
        }
        return _total;
    }

    function Launch() public onlyOwner {
        require(!init);
        launchTimestamp = block.timestamp;
        init = true;
    }

    function StopWithdraw() public onlyOwner {
        require(init);
        init = false;
    }

    function withdrawRef() public {
        require(init);
        deposit_status storage depositStatus = depositQuery[msg.sender];
        require(depositStatus.status, "You should deposit first");
        require(
            !withdrawInit[msg.sender].init,
            "You have exceed the amount to withdraw"
        );
        uint256 totalReward = 0;
        for (uint256 i = 0; i <= 11; i++) {
            uint256 _amtx = RefDailyROI(msg.sender, i);
            totalReward = _amtx + totalReward;
            RefRewards[msg.sender][i].block_id = block.number;
        }

        uint256 levelAmm = 0;

        for (uint256 j = 0; j <= 11; j++) {
            uint256 _amm = LevelTotal(msg.sender, j);
            levelAmm = _amm;
        }

        if (totalReward >= depositQuery[msg.sender].investment) {
            uint256 togetNow = depositQuery[msg.sender].investment;
            uint256 devFee_ = DevFee(togetNow);

            uint256 totalFee = devFee_;
            uint256 total = togetNow - totalFee;
            payable(developerAddress).transfer(devFee_);
            payable(msg.sender).transfer(total);

            uint256 totalWithdrawRef = togetNow +
                withdrawn[msg.sender].total_withdrawn;
            withdrawn[msg.sender] = ref_withdraw(msg.sender, totalWithdrawRef);

            totalWithdrawals = togetNow + totalWithdrawals;
        } else {
            uint256 devFee_ = DevFee(totalReward);

            uint256 totalFee = devFee_;
            uint256 total = totalReward - totalFee;
            payable(developerAddress).transfer(devFee_);
            payable(msg.sender).transfer(total);

            uint256 totalWithdrawRef = totalReward +
                withdrawn[msg.sender].total_withdrawn;
            withdrawn[msg.sender] = ref_withdraw(msg.sender, totalWithdrawRef);

            totalWithdrawals = totalReward + totalWithdrawals;
        }

        if (
            withdrawn[msg.sender].total_withdrawn +
                ROI_WITHDRAW[msg.sender].totalWithdraw >=
            depositQuery[msg.sender].investment * profitMultiplier
        ) {
            withdrawInit[msg.sender] = Record5x(msg.sender, true);
        }

        emit WithdrawRef(msg.sender, totalReward);
    }

    function DevFee(uint256 _amount) public view returns (uint256) {
        return (_amount / divisionFactor) * level1CommissionRate;
    }

    function RefFee(uint256 _amount) public view returns (uint256) {
        return (_amount / divisionFactor) * directCommissionRate;
    }

    receive() external payable {}
}
