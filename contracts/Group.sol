// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Group is Initializable, OwnableUpgradeable {
    struct Expense {
        address spender;
        uint256 amount;
        string note;
    }

    address public admin;
    mapping(address => string) public userNames;
    mapping(address => int256) public balances;
    mapping(address => Expense[]) public expenses;
    address[] public members;

    IERC20 public token;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner(), "Only admin or owner can perform this action");
        _;
    }

    event ExpenseAdded(address indexed spender, uint256 amount, string note);
    event ExpenseRemoved(address indexed spender, uint256 amount, string note);
    event FundsSplit(address indexed from, address indexed to, uint256 amount);
    event ERC20FundsSplit(address indexed from, address indexed to, uint256 amount, address token);

    function initialize(address _admin, address _tokenAddress) external initializer {
        __Ownable_init(_admin);
        admin = _admin;
        token = IERC20(_tokenAddress);
    }

    // Set userName and address
    function setName(address user, string memory name) external onlyAdminOrOwner {
        userNames[user] = name;
    }

    // Admin can add a new user to the group
    function addUser(address user) external onlyAdmin {
        members.push(user);
    }

    // Admin can remove a user from the group
    function removeUser(address user) external onlyAdmin {
        uint256 index;
        bool userFound = false;
        for (index = 0; index < members.length; index++) {
            if (members[index] == user) {
                userFound = true;
                break;
            }
        }
        if (userFound) {
            members[index] = members[members.length - 1];
            members.pop();
        }
    }

    // Any group member can add an expense
    function addExpense(uint256 amount, string memory note) external {
        require(isMember(msg.sender), "Only group members can add expenses");
        expenses[msg.sender].push(Expense(msg.sender, amount, note));

        emit ExpenseAdded(msg.sender, amount, note);
    }

    // Admin can remove an expense
    function removeExpense(address spender, uint256 index) external onlyAdmin {
        require(index < expenses[spender].length, "Invalid expense index");
        Expense memory expense = expenses[spender][index];
      
        // Remove expense from the list
        for (uint256 i = index; i < expenses[spender].length - 1; i++) {
            expenses[spender][i] = expenses[spender][i + 1];
        }
        expenses[spender].pop();
        emit ExpenseRemoved(spender, expense.amount, expense.note);
    }

    // Retrieve all recorded expenses
    function getExpenses() external view returns (Expense[] memory) {
        uint256 totalExpensesCount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            totalExpensesCount += expenses[members[i]].length;
        }
        Expense[] memory allExpenses = new Expense[](totalExpensesCount);
        uint256 index = 0;
        for (uint256 i = 0; i < members.length; i++) {
            for (uint256 j = 0; j < expenses[members[i]].length; j++) {
                allExpenses[index] = expenses[members[i]][j];
                index++;
            }
        }
        return allExpenses;
    }

    // Check if the contract has sufficient funds to settle all positive balances
    function isFunded() external view returns (bool) {
        return _isFunded();
    }

    //summary
    function getSummary() public view returns (uint256){
        uint256 totlatAmount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (balances[members[i]] > 0) {
                totlatAmount += uint256(balances[members[i]]);
            }
        }
        return totlatAmount;
    }

    // Internal function to check if the contract has sufficient funds
    function _isFunded() internal view returns (bool) {
        uint256 total = getSummary();
        return token.balanceOf(address(this)) >= total;
    }
    
    // Split ERC20 funds among members based on their balances
    function splitFunds() external {
        require(_isFunded(), "Contract does not have sufficient funds");

        for (uint256 i = 0; i < members.length; i++) {
            if (balances[members[i]] > 0) {
                address recipient = members[i];
                uint256 amount = uint256(balances[members[i]]);
                emit ERC20FundsSplit(address(this), recipient, amount, address(token));
            }
        }
    }

    // Check if an address is a member of the group
    function isMember(address user) internal view returns (bool) {
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                return true;
            }
        }
        return false;
    }
}



