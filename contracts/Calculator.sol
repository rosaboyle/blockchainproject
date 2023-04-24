pragma solidity >=0.4.22 <0.9.0;

contract Calculator {
    uint c;

    function add(uint a, uint b) public {
        c = a + b;
    }

}