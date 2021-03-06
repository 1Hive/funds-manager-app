pragma solidity ^0.4.24;

import "./FundsManager.sol";
import "./GnosisSafe.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";

// This contract must be granted the permission to transfer funds on the Gnosis Safe it accepts
contract GnosisSafeFundsManager is FundsManager {

    bytes4 public constant TRANSFER_SELECTOR = 0xa9059cbb; // Equivalent of bytes4(keccak256("transfer(address,uint256)"))
    address public constant ETH = address(0);

    GnosisSafe public gnosisSafe;

    constructor(GnosisSafe _gnosisSafe) FundsManager(msg.sender) public {
        gnosisSafe = _gnosisSafe;
    }

    function fundsOwner() public view returns (address) {
        return address(gnosisSafe);
    }

    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(gnosisSafe).balance;
        } else {
            ERC20 token = ERC20(_token);
            return token.balanceOf(address(gnosisSafe));
        }
    }

    function transfer(address _token, address _beneficiary, uint256 _amount) public onlyFundsUser {
        bool success;
        bytes memory returnData;

        if (_token == ETH) {
            (success, returnData) = gnosisSafe.execTransactionFromModuleReturnData(_beneficiary, _amount, new bytes(0), GnosisSafe.Operation.Call);
        } else {
            bytes memory transferBytes = abi.encodeWithSelector(TRANSFER_SELECTOR, _beneficiary, _amount);
            (success, returnData) = gnosisSafe.execTransactionFromModuleReturnData(_token, 0, transferBytes, GnosisSafe.Operation.Call);
        }

        bool returnBool = false;
        assembly {
            // Load the data after 32 bytes length slot, eg add 0x20
            returnBool := mload(add(returnData, 0x20))
        }

        require(success, "ERR:TRANSFER_REVERTED");
        if (_token != ETH) { require(returnBool, "ERR:TRANSFER_NOT_RETURN_TRUE"); }
    }
}
