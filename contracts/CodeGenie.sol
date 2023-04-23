pragma solidity ^0.8.0;
contract CodeGenie {
   function withdraw(uint withdraw_amount) public {
      require(withdraw_amount <= 100000000000000000000);
      payable(msg.sender).transfer(withdraw_amount);
   }

   fallback() external payable {}
}