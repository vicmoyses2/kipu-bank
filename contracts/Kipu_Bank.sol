// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title KipuBank
 * @notice Simple capped bank contract that allows users to deposit and withdraw ETH
 *         up to a global capacity (bank cap) defined at deployment.
 * @dev Uses a custom nonReentrant modifier and private helpers to improve readability and safety.
 */
contract KipuBank {
    // -------------------------------------------------------------------------
    // Immutable configuration
    // -------------------------------------------------------------------------

    /// @notice Global maximum amount of ETH the contract may hold (bank cap)
    uint256 public immutable i_bankCapacity;

    /// @notice Maximum amount allowed per withdrawal transaction
    uint256 public immutable i_maxWithdrawPerTx;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Count successful deposits
    uint256 public depositCount;

    /// @notice Count successful withdrawals
    uint256 public withdrawCount;

    /// @notice Mapping of user address to its internal balance
    mapping(address => uint256) public userBalance;

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------
    error ExceedsBankCapacity();
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidMaxWithdrawAmount();
    error InvalidDepositPath();
    error TransferFailed();
    error ReentrancyGuard();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------
    event SuccessfullyDeposited(address indexed user, uint256 amount);
    event SuccessfullyWithdrawn(address indexed user, uint256 amount);

    // -------------------------------------------------------------------------
    // Reentrancy guard (minimal)
    // -------------------------------------------------------------------------
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrancyGuard();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Ensures the provided amount is greater than zero
    modifier onlyPositiveAmount(uint256 amount) {
        if (amount == 0) revert InvalidAmount();
        _;
    }

    /// @dev Ensures the provided user has a non-zero balance
    modifier onlyExistingUser(address user) {
        if (userBalance[user] == 0) revert InsufficientBalance();
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @notice Initializes the bank with a global capacity and a per-transaction withdraw cap.
     * @param bankCapacity The maximum total ETH allowed to be held by the contract.
     * @param maxWithdrawPerTx The maximum amount a user can withdraw per transaction.
     */
    constructor(uint256 bankCapacity, uint256 maxWithdrawPerTx) {
        i_bankCapacity = bankCapacity;
        i_maxWithdrawPerTx = maxWithdrawPerTx;
    }

    // -------------------------------------------------------------------------
    // Public / External Read Functions
    // -------------------------------------------------------------------------

    /**
     * @notice Returns the actual ETH balance held by the contract (on-chain truth).
     * @return actualBalance The contract's ETH balance.
     */
    function getContractBalance() public view returns (uint256 actualBalance) {
        actualBalance = address(this).balance;
    }

    /**
     * @notice Returns the recorded balance for a given user.
     * @dev Reverts if the user has zero balance to avoid misleading "0" reads where a balance is expected.
     * @param user The user address to query.
     * @return balance The user's internal tracked balance.
     */
    function getUserBalance(address user)
        external
        view
        returns (uint256 balance)
    {
        if (userBalance[user] == 0) revert InsufficientBalance();
        balance = userBalance[user];
    }

    // -------------------------------------------------------------------------
    // Deposit / Withdraw
    // -------------------------------------------------------------------------

    /**
     * @notice Deposits ETH into the bank for the caller.
     * @dev
     * - Callable only via this function (receive/fallback revert).
     * - The bank capacity check considers that `address(this).balance`
     *   already includes `msg.value` at this execution point.
     */
    function deposit() external payable onlyPositiveAmount(msg.value) {
        _checkBankCapacityAfterReceive(); // reverts if current balance exceeds cap

        userBalance[msg.sender] += msg.value;
        unchecked {
            depositCount++;
        }

        emit SuccessfullyDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws a specified amount of ETH from caller's balance.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount)
        external
        nonReentrant
        onlyPositiveAmount(amount)
        onlyExistingUser(msg.sender)
    {
        _hasSufficientBalance(msg.sender, amount);

        if (amount > i_maxWithdrawPerTx) {
            revert InvalidMaxWithdrawAmount();
        }

        _executeWithdraw(msg.sender, amount);
    }

    // -------------------------------------------------------------------------
    // Private Helpers
    // -------------------------------------------------------------------------

    /**
     * @dev Ensures the current contract balance does not exceed the global cap.
     *      This function MUST be called only after the ETH has been received (inside `deposit`).
     *      At this point, `address(this).balance` already includes `msg.value`.
     */
    function _checkBankCapacityAfterReceive() private view {
        if (address(this).balance > i_bankCapacity) {
            revert ExceedsBankCapacity();
        }
    }

    /**
     * @dev Reverts if `user` balance is smaller than `amount`.
     */
    function _hasSufficientBalance(address user, uint256 amount)
        private
        view
    {
        if (userBalance[user] < amount) revert InsufficientBalance();
    }

    /**
     * @dev Deducts internal balance and transfers ETH to `user`.
     *      Uses `.call{value: amount}("")` and checks success.
     */
    function _executeWithdraw(address user, uint256 amount) private {
        unchecked {
            userBalance[user] -= amount;
            withdrawCount++;
        }

        (bool ok, ) = payable(user).call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit SuccessfullyWithdrawn(user, amount);
    }

    // -------------------------------------------------------------------------
    // Receive / Fallback — block unintended deposits
    // -------------------------------------------------------------------------

    /**
     * @dev Reject plain ETH transfers; enforce using `deposit()`.
     */
    receive() external payable {
        revert InvalidDepositPath();
    }

    /**
     * @dev Reject unknown calls and ETH with data; enforce using `deposit()`.
     */
    fallback() external payable {
        revert InvalidDepositPath();
    }
}
