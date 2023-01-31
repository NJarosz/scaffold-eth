import React, { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Button, Card, List, Spin, Popover, Form, Switch, Typography } from "antd";
import { Address, AddressInput } from "../components";
import { ethers } from "ethers";
import { useDebounce } from "../hooks";
import { useEventListener } from "eth-hooks/events/useEventListener";

function Drinks({
  readContracts,
  mainnetProvider,
  blockExplorer,
  totalSupply,
  DEBUG,
  writeContracts,
  tx,
  address,
  localProvider,
  FalgeneContract,
  startBlock,
}) {
  const rawDrinks = useEventListener(readContracts, FalgeneContract, "Drink", localProvider, startBlock - 0);
  const drinks = useDebounce(rawDrinks, 1000);
  if (DEBUG) console.log("DRINKS", drinks);
  const rawPowder = useEventListener(readContracts, FalgeneContract, "Powder", localProvider, startBlock - 0);
  const powder = useDebounce(rawPowder, 1000);
  if (DEBUG) console.log("POWDER", powder);
  const rawRefill = useEventListener(readContracts, FalgeneContract, "Refill", localProvider, startBlock - 0);
  const refill = useDebounce(rawRefill, 1000);

  const events = [];

  for (let i = 0; i <= drinks.length; i++) {
    events.push(drinks[i]);
  }

  for (let i = 0; i <= powder.length; i++) {
    events.push(powder[i]);
  }

  for (let i = 0; i <= refill.length; i++) {
    events.push(refill[i]);
  }


  const filteredEvents = events.filter(function (element) {
    return element !== undefined;
  });

  console.log("EVENTS", filteredEvents);

  return (
    <div style={{ margin: "auto", paddingBottom: 32 }}>
      <List
        size="large"
        locale={{ emptyText: `waiting for events...` }}
        dataSource={filteredEvents.sort((a, b) => b.blockNumber - a.blockNumber)}
        renderItem={item => {
          return (
            <List.Item key={item.blockNumber + "_" + item.args.sender} style={{ justifyContent: "center" }}>
              {item.args.drinker && item.args.sender == item.args.drinker ? (
                <Typography.Text style={{ fontSize: 28 }}>
                  {`💧:  `}
                  <Address
                    blockExplorer={blockExplorer}
                    address={item.args.sender}
                    ensProvider={mainnetProvider}
                    style={{ fontSize: 24 }}
                  />
                  {`  took a sip`}
                </Typography.Text>
              ) : item.args.drinker ? (
                <Typography.Text style={{ fontSize: 28 }}>
                  {`🚰:  `}
                  <Address
                    blockExplorer={blockExplorer}
                    address={item.args.sender}
                    ensProvider={mainnetProvider}
                    fontSize={24}
                  />
                  {` gave a pour to `}
                  <Address
                    blockExplorer={blockExplorer}
                    address={item.args.drinker}
                    ensProvider={mainnetProvider}
                    fontSize={24}
                  />
                </Typography.Text>
              ) : item.args.powder ? (
                <Typography.Text style={{ fontSize: 28 }}>
                  {`🩸:  `}
                  <Address
                    blockExplorer={blockExplorer}
                    address={item.args.sender}
                    ensProvider={mainnetProvider}
                    style={{ fontSize: 24 }}
                  />
                  {`  added powder`}
                </Typography.Text>
              ) : (
                <Typography.Text style={{ fontSize: 28 }}>
                  {`🚰:  `}
                  <Address
                    blockExplorer={blockExplorer}
                    address={item.args.sender}
                    ensProvider={mainnetProvider}
                    style={{ fontSize: 24 }}
                  />
                  {` refilled bottle`}
                </Typography.Text>
              )}
            </List.Item>
          );
        }}
      />
    </div>
  );
}

export default Drinks;
