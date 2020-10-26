//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "@nomiclabs/buidler/console.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract Greeter is Initializable {
    string greeting;

    function initialize(string memory _greeting)
        public
        initializer
    {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
