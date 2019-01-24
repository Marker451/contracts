pragma solidity ^0.4.23;

contract Matr {
    struct coord {
        uint x;
        uint y;
    }
    uint public randSalt = 0;
    uint256 prize = 0;
    uint constant size = 11;
    uint256 constant ticketPrice = 1 ether;
    mapping(byte => bool )operations;//left  right up down
    mapping(uint => coord) public phones;
    mapping(uint => bool) public phonesAviable;
    uint phoneCount = 0;
    coord public bob;
    mapping(address => uint) public steps;

    event GotPhone(address winer, uint index);
    event Move(address sender, string op, uint x, uint y);
    event ClearingPrize(address winer, uint256 prize);

    function Init(uint phoneNum) public{
        for (uint i =0; i< phoneNum; i++) {
            uint _x = getRand(size, 0);
            uint _y =  getRand(size, 0);
            coord memory _coord = coord({x:_x,y:_y});
            phones[i] = _coord;
            phonesAviable[i] = true;
        }
        phoneCount = phoneNum;
        bob.x = (size/2)+1;
        bob.y = bob.x;
        operations["l"] = true;
        operations["r"] = true;
        operations["u"] = true;
        operations["d"] = true;
    }

    function getRand(uint limit, uint luckyNum) private returns (uint){
        randSalt++;
        return uint(sha256(now,msg.sender,randSalt, luckyNum))%limit;
    }

    function toss(uint luckyNum) public payable returns(uint num){
        require(msg.value == ticketPrice);
        prize = prize + msg.value;
        num = getRand(6, luckyNum)+1;
        steps[msg.sender] = num;
        return;
    }

    function move(string op) public returns (bool win){
        assert(checkOp(op));
        steps[msg.sender] = 0;
        assert(makeCoord(op));
        emit Move(msg.sender, op, bob.x, bob.y);
        bool success;
        uint index;
        (success, index) = gotPhone();
        if(!success) {
            return false;
        }
        bool finally  = index == phoneCount - 1;
        clearingPrize(finally);
        return true;
    }

    function clearingPrize(bool finally)private{
        uint256 payPrize = 0;
        if(finally){
            payPrize = prize;
        }else{
            payPrize = prize * 80 /100;
        }
        msg.sender.transfer(payPrize);
        emit ClearingPrize(msg.sender, payPrize);
    }

    function makeCoord(string opStr) private returns(bool success){
        bytes memory op = bytes(opStr);
        for(uint i = 0; i < op.length; i++){
            if(op[i] == "l"){
                if(bob.x == 0){
                    return false;
                }
                bob.x--;
                continue;
            }
            if(op[i] == "r"){
                if(bob.x == size-1){
                    return false;
                }
                bob.x++;
                continue;

            }
            if(op[i] == "u"){
                if(bob.y == size-1){
                    return false;
                }
                bob.y++;
                continue;
            }
            if(op[i] == "d"){
                if(bob.y == 0){
                    return false;
                }
                bob.y--;
            }
        }
        return true;
    }
    function checkOp(string opStr) private view returns (bool){
        bytes memory op = bytes(opStr);
        if(op.length > 6 || op.length == 0) {
            return false;
        }
        if(op.length != steps[msg.sender]){
            return false;
        }
        for(uint i=0; i<op.length; i++){
            if(operations[op[i]] != true){
                return false;
            }
            if(i > 0){
                if(getRevertOp(op[i]) == op[i-1]){
                    return false;
                }
            }

        }
        return true;
    }

    function getRevertOp(byte op) private pure returns(byte){
        if(op == "l"){
            return "r";
        }
        if(op == "r"){
            return "l";
        }
        if(op == "u"){
            return "d";
        }
        if(op == "d"){
            return "u";
        }
        return "";
    }

    function gotPhone() private view returns(bool success, uint index){
        for(uint i = 0; i < phoneCount; i++){
            if(phonesAviable[i] && phones[i].x == bob.x && phones[i].y == bob.y){
                emit GotPhone(msg.sender, i);
                phonesAviable = false;
                return (true, i);
            }
        }
        return (false, i);
    }

}