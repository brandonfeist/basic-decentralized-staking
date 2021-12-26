pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
  uint256 public constant threshold = 1 ether;

  ExampleExternalContract public exampleExternalContract;
  bool public openForWithdraw;
  uint256 public deadline;
  mapping ( address => uint256 ) public balances;

  event Stake(address indexed sender, uint256 staked);

  constructor(address exampleExternalContractAddress) public {
    deadline = block.timestamp + 30 seconds;
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake is completed");

    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
    require(now < deadline, "Cannot stake after the deadline.");
    require(msg.value > 0, "Must stake more than 0 ether.");

    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(now >= deadline, "Cannot execute the stake before the deadline.");

    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
      exampleExternalContract.complete{value: 0}();
    }
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable _to) public {
    require(openForWithdraw, "The contract is not open for withdraw.");

    address owner = msg.sender;
    uint256 ammount = balances[owner];

    require(ammount > 0, "Balance required to withdraw.");

    (bool success, ) = _to.call{value: ammount}("");
    balances[owner] = 0;

    require(success, "Failed to send Ether.");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (now >= deadline) {
      return 0;
    } else {
      return deadline - now;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
