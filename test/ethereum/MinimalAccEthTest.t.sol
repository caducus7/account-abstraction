//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccountEthereum} from "src/ethereum/MinimalAccountEthereum.sol";
import {DeployMinimalEth} from "script/DeployMinimalEth.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccEthTest is Test {
    HelperConfig helperConfig;
    MinimalAccountEthereum minimalAccount;
    ERC20Mock usdc;
    uint256 AMOUNT = 1e18;
    address randomUser = makeAddr("randomUser");

    function setUp() public {
        DeployMinimalEth deployer = new DeployMinimalEth();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        usdc = new ERC20Mock();
    }

    function testOwnerCanExecuteCommands() public {
        //Arrange

        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        uint256 value = 0;
        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //Act

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        //Assert

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecute() public {
        //Arrange

        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        uint256 value = 0;
        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //Act

        vm.prank(randomUser);
        vm.expectRevert();
        minimalAccount.execute(dest, value, functionData);
    }
}
