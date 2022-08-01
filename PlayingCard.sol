// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Polygon Mumbai Testnet coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Link Token contract address at Polygon Mumbai Testnet
  address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 500000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  5;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 s_subscriptionId; // generate new
  address s_owner;
  uint256 constant public totalTries = 5;
  bool private result = false;
  string public trumCard;
  string[] public selectedCards = new string[](totalTries);

  constructor(string memory _trumCard) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    s_owner = msg.sender;
    trumCard = _trumCard;
    //Create a new subscription when you deploy the contract.
    createNewSubscription();
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
    // Add this contract as a consumer of its own subscription.
    COORDINATOR.addConsumer(s_subscriptionId, address(this));
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription(uint256 amount) external onlyOwner {
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    // Add a consumer contract to the subscription.
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    LINKTOKEN.transfer(to, amount);
  }

  // Assumes the subscription is funded sufficiently.
  function shuffleCards() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  function setAllSelectedCards() public {
    uint selectedValue;
    for(uint i = 0; i < totalTries; i++){
        selectedValue = (s_randomWords[i] % 52) + 1;
        selectedCards[i] = getCards(selectedValue);
        if(keccak256(abi.encode(getCards(selectedValue))) == keccak256(abi.encode(trumCard))){
            result = true;
        }
    }
  }

  function getAllSelectedCards() external view returns(string[] memory){
    return selectedCards;
  }

    function getResult() external view returns(string memory){
    if(result == true){
      return "HURRAH! YOU WON!!!!";
    }
    else{
      return "SORRY! YOU LOSE";
    }
  }

  
  function getCards(uint256 id) private pure returns (string memory) {
    string[52] memory cardNames = [
      'Clubs Ace',
      'Clubs 2',
      'Clubs 3',
      'Clubs 4',
      'Clubs 5', 
      'Clubs 6',
      'Clubs 7',
      'Clubs 8',
      'Clubs 9',
      'Clubs 10',
      'Clubs Jack',
      'Clubs Queen',
      'Clubs King',
      'Diamonds Ace',
      'Diamonds 2',
      'Diamonds 3',
      'Diamonds 4',
      'Diamonds 5', 
      'Diamonds 6',
      'Diamonds 7',
      'Diamonds 8',
      'Diamonds 9',
      'Diamonds 10',
      'Diamonds Jack',
      'Diamonds Queen',
      'Diamonds King',
      'Hearts Ace',
      'Hearts 2',
      'Hearts 3',
      'Hearts 4',
      'Hearts 5', 
      'Hearts 6',
      'Hearts 7',
      'Hearts 8',
      'Hearts 9',
      'Hearts 10',
      'Hearts Jack',
      'Hearts Queen',
      'Hearts King',
      'Spades Ace',
      'Spades 2',
      'Spades 3',
      'Spades 4',
      'Spades 5', 
      'Spades 6',
      'Spades 7',
      'Spades 8',
      'Spades 9',
      'Spades 10',
      'Spades Jack',
      'Spades Queen',
      'Spades King'
      ];
  return cardNames[id - 1];
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
