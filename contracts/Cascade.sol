pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./lib/SafeMathInt.sol";
import "./BaseToken.sol";

contract Cascade is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct Deposit {
        uint256 lpTokensDeposited;
        uint256 depositTimestamp;
        uint8   multiplierLevel;
        uint256 mostRecentWithdrawal;
    }

    mapping(address => Deposit) internal deposits;
    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSecondsLevel1;
    uint256 public totalDepositSecondsLevel2;
    uint256 public totalDepositSecondsLevel3;
    uint256 public lastAccountingUpdateTimestamp;
    IERC20 public lpToken;
    BaseToken public BASE;
    uint256 public minTimeBetweenWithdrawals;

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    function setLPToken(address _lpToken)
        public
        onlyOwner
    {
        lpToken = IERC20(_lpToken);
    }

    function setBaseToken(address _baseToken)
        public
        onlyOwner
    {
        BASE = BaseToken(_baseToken);
    }

    function setMinTimeBetweenWithdrawals(uint256 _minTimeBetweenWithdrawals)
        public
        onlyOwner
    {
        minTimeBetweenWithdrawals = _minTimeBetweenWithdrawals;
    }

    function deposit(uint256 amount)
        public
    {
        updateAccounting();

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        Deposit storage deposit = deposits[msg.sender];

        if (deposit.multiplierLevel == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposit.lpTokensDeposited);
        } else if (deposit.multiplierLevel == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(deposit.lpTokensDeposited);
        }
        totalDepositedLevel1 = totalDepositedLevel1.add(amount);

        deposit.lpTokensDeposited = deposit.lpTokensDeposited.add(amount);
        deposit.depositTimestamp = now;
        deposit.multiplierLevel = 1;
    }

    function depositInfo(address user)
        public
        view
        returns (uint256 lpTokensDeposited, uint256 depositTimestamp, uint8 multiplierLevel)
    {
        return (deposits[user].lpTokensDeposited, deposits[user].depositTimestamp, deposits[user].multiplierLevel);
    }

    function updateAccounting()
        public
    {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        totalDepositSecondsLevel1 = totalDepositSecondsLevel1.add(totalDepositedLevel1.mul(delta));
        totalDepositSecondsLevel2 = totalDepositSecondsLevel2.add(totalDepositedLevel2.mul(delta));
        totalDepositSecondsLevel3 = totalDepositSecondsLevel3.add(totalDepositedLevel3.mul(delta));

        lastAccountingUpdateTimestamp = now;
    }

    function upgradeMultiplierLevel(address user)
        public
    {
        updateAccounting();

        Deposit storage deposit = deposits[user];
        require(deposit.multiplierLevel > 0, "no deposit");
        require(deposit.multiplierLevel < 3, "fully upgraded");

        uint256 duration = now.sub(deposit.depositTimestamp);

        if (deposit.multiplierLevel == 1 && duration >= 60 days) {
            deposit.multiplierLevel = 3;
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposit.lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(deposit.lpTokensDeposited);

        } else if (deposit.multiplierLevel == 1 && duration >= 30 days) {
            deposit.multiplierLevel = 2;
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposit.lpTokensDeposited);
            totalDepositedLevel2 = totalDepositedLevel2.add(deposit.lpTokensDeposited);

        } else if (deposit.multiplierLevel == 2 && duration >= 60 days) {
            deposit.multiplierLevel = 3;
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposit.lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(deposit.lpTokensDeposited);

        } else {
            revert("ineligible");
        }
    }

    function owedTo(address user)
        public
        view
        returns (uint256 amount)
    {
        Deposit storage deposit = deposits[user];

        uint256 userDepositSeconds =
            deposit.lpTokensDeposited
              .mul(now.sub(deposit.depositTimestamp))
              .mul(deposit.multiplierLevel);

        uint256 totalDepositSeconds =
            totalDepositSecondsLevel1
              .add(totalDepositSecondsLevel2.mul(2))
              .add(totalDepositSecondsLevel3.mul(3));

        uint256 rewardsPool = BASE.balanceOf(address(this));

        return (rewardsPool.mul(userDepositSeconds)).div(totalDepositSeconds);
    }

    function claimBASE(uint256 amount)
        public
    {
        updateAccounting();

        Deposit storage deposit = deposits[msg.sender];
        require(deposit.multiplierLevel > 0, "doesn't exist");
        require(now > deposit.mostRecentWithdrawal.add(minTimeBetweenWithdrawals), "too soon");
        require(BASE.balanceOf(address(this)) >= amount, "available tokens");

        uint256 owed = owedTo(msg.sender);
        require(owed >= amount, "amount");

        bool ok = BASE.transfer(msg.sender, owed);
        require(ok, "transfer");
    }

    function withdrawLPTokens(uint256 amount)
        public
    {
        Deposit storage deposit = deposits[msg.sender];
        require(deposit.multiplierLevel > 0, "doesn't exist");
        require(deposit.lpTokensDeposited >= amount, "amount");

        bool ok = lpToken.transfer(msg.sender, amount);
        require(ok, "transfer");

        if (deposit.multiplierLevel == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.sub(amount);
        } else if (deposit.multiplierLevel == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(amount);
        } else if (deposit.multiplierLevel == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(amount);
        }

        deposit.lpTokensDeposited = deposit.lpTokensDeposited.sub(amount);
        if (deposit.lpTokensDeposited == 0) {
            delete deposits[msg.sender];
        }
    }

    function adminWithdrawBASE(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "bad amount");

        bool ok = BASE.transfer(recipient, amount);
        require(ok, "transfer");
    }
}
