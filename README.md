GREETER_B_ADDRESS=`forge create --rpc-url $URL_CHAIN_B --private-key $PRIVATE_KEY Greeter --broadcast | awk '/Deployed to:/ {print $3}'`

cast call --rpc-url $URL_CHAIN_B $GREETER_B_ADDRESS "greet()" | cast --to-ascii 
cast send --private-key $PRIVATE_KEY --rpc-url $URL_CHAIN_B $GREETER_B_ADDRESS "setGreeting(string)" Hello
cast call --rpc-url $URL_CHAIN_B $GREETER_B_ADDRESS "greet()" | cast --to-ascii


CHAIN_ID_B=`cast chain-id --rpc-url $URL_CHAIN_B`

GREETER_A_ADDRESS=`forge create --rpc-url $URL_CHAIN_A --private-key $PRIVATE_KEY --broadcast GreetingSender --constructor-args $GREETER_B_ADDRESS $CHAIN_ID_B | awk '/Deployed to:/ {print $3}'`


cast call --rpc-url $URL_CHAIN_B $GREETER_B_ADDRESS "greet()" | cast --to-ascii 
cast send --private-key $PRIVATE_KEY --rpc-url $URL_CHAIN_A $GREETER_A_ADDRESS "setGreeting(string)" "Hello from chain A"
sleep 4
cast call --rpc-url $URL_CHAIN_B $GREETER_B_ADDRESS "greet()" | cast --to-ascii




---- FETCHING


cast call --private-key $PRIVATE_KEY --rpc-url $URL_CHAIN_A $GREETER_A_ADDRESS "getLastKnownGreeting()"

cast send --private-key $PRIVATE_KEY --rpc-url $URL_CHAIN_A $GREETER_A_ADDRESS "fetchCurrentGreeting()"
