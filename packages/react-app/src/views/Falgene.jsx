import React, { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Button, Card, List, Spin, Popover, Form, Switch } from "antd";
import { RedoOutlined } from "@ant-design/icons";
import { Address, AddressInput } from "../components";
import { useDebounce } from "../hooks";
import { ethers } from "ethers";
import { useEventListener } from "eth-hooks/events/useEventListener";

function Falgene({
  readContracts,
  mainnetProvider,
  blockExplorer,
  totalSupply,
  priceToRefill,
  pricePowder,
  DEBUG,
  writeContracts,
  tx,
  address,
  localProvider,
  FalgeneContract,
  balance,
  startBlock,
}) {
  const [allFalgene, setallFalgene] = useState({});
  const [loadingFalgene, setloadingFalgene] = useState(true);
  const perPage = 12;
  const [page, setPage] = useState(0);
  if (DEBUG) console.log("Falgene Total Supply", totalSupply);

  const fetchMetadataAndUpdate = async id => {
    try {
      const tokenURI = await readContracts[FalgeneContract].tokenURI(id);
      const jsonManifestString = atob(tokenURI.substring(29));

      try {
        const jsonManifest = JSON.parse(jsonManifestString);
        const collectibleUpdate = {};
        collectibleUpdate[id] = { id: id, uri: tokenURI, ...jsonManifest };

        setallFalgene(i => ({ ...i, ...collectibleUpdate }));
      } catch (e) {
        console.log(e);
      }
    } catch (e) {
      console.log(e);
    }
  };

  const updateallFalgene = async fetchAll => {
    if (readContracts[FalgeneContract] && totalSupply /*&& totalSupply <= receives.length*/) {
      setloadingFalgene(true);
      let numberSupply = totalSupply;

      let tokenList = Array(numberSupply).fill(0);

      tokenList.forEach((_, i) => {
        let tokenId = i + 1;
        if (tokenId <= numberSupply - page * perPage && tokenId >= numberSupply - page * perPage - perPage) {
          fetchMetadataAndUpdate(tokenId);
        } else if (!allFalgene[tokenId]) {
          const simpleUpdate = {};
          simpleUpdate[tokenId] = { id: tokenId };
          setallFalgene(i => ({ ...i, ...simpleUpdate }));
        }
      });

      setloadingFalgene(false);
    }
  };

  const updateYourFalgene = async () => {
    for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
      try {
        const tokenId = await readContracts[FalgeneContract].tokenOfOwnerByIndex(address, tokenIndex);
        fetchMetadataAndUpdate(tokenId);
      } catch (e) {
        console.log(e);
      }
    }
  };

  const updateOneFalgene = async id => {
    if (readContracts[FalgeneContract] && totalSupply) {
      fetchMetadataAndUpdate(id);
    }
  };

  useEffect(() => {
    if (totalSupply && totalSupply > 0) updateallFalgene(false);
  }, [readContracts[FalgeneContract], (totalSupply || "0").toString(), page]);

  const onFinishFailed = errorInfo => {
    console.log("Failed:", errorInfo);
  };

  const [form] = Form.useForm();
  const sendForm = id => {
    const [sending, setSending] = useState(false);

    return (
      <div>
        <Form
          form={form}
          layout={"inline"}
          name="sendBottle"
          initialValues={{ tokenId: id }}
          onFinish={async values => {
            setSending(true);
            try {
              const txCur = await tx(
                writeContracts[FalgeneContract]["safeTransferFrom(address,address,uint256)"](
                  address,
                  values["to"],
                  id,
                ),
              );
              await txCur.wait();
              updateOneFalgene(id);
              setSending(false);
            } catch (e) {
              console.log("send failed", e);
              setSending(false);
            }
          }}
          onFinishFailed={onFinishFailed}
        >
          <Form.Item
            name="to"
            rules={[
              {
                required: true,
                message: "Which address should receive this Bottle?",
              },
            ]}
          >
            <AddressInput ensProvider={mainnetProvider} placeholder={"to address"} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={sending}>
              Send
            </Button>
          </Form.Item>
        </Form>
      </div>
    );
  };

  const [pourForm] = Form.useForm();
  const pour = id => {
    const [pouring, setPouring] = useState(false);

    return (
      <div>
        <Form
          form={pourForm}
          layout={"inline"}
          name="pourWater"
          initialValues={{ tokenId: id }}
          onFinish={async values => {
            setPouring(true);
            try {
              const txCur = await tx(writeContracts[FalgeneContract]["pour"](id, values["to"]));
              await txCur.wait();
              updateOneFalgene(id);
              setPouring(false);
            } catch (e) {
              console.log("pour failed", e);
              setPouring(false);
            }
          }}
          onFinishFailed={onFinishFailed}
        >
          <Form.Item
            name="to"
            rules={[
              {
                required: true,
                message: "Who's getting a pour?",
              },
            ]}
          >
            <AddressInput ensProvider={mainnetProvider} placeholder={"to address"} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={pouring}>
              Pour
            </Button>
          </Form.Item>
        </Form>
      </div>
    );
  };

  let filteredFalgenes = Object.values(allFalgene).sort((a, b) => b.id - a.id);
  const [mine, setMine] = useState(false);
  if (mine == true && address && filteredFalgenes) {
    filteredFalgenes = filteredFalgenes.filter(function (el) {
      return el.owner == address.toLowerCase();
    });
  }

  return (
    <div style={{ width: "auto", margin: "auto", paddingBottom: 25, minHeight: 800 }}>
      {false ? (
        <Spin style={{ marginTop: 100 }} />
      ) : (
        <div>
          <div style={{ marginBottom: 5 }}>
            <Button
              onClick={() => {
                return updateallFalgene(true);
              }}
            >
              Refresh
            </Button>
            <Switch
              disabled={loadingFalgene}
              style={{ marginLeft: 5 }}
              value={mine}
              onChange={() => {
                setMine(!mine);
                updateYourFalgene();
              }}
              checkedChildren="mine"
              unCheckedChildren="all"
            />
          </div>
          <List
            grid={{
              gutter: 16,
              xs: 1,
              sm: 2,
              md: 4,
              lg: 4,
              xl: 6,
              xxl: 4,
            }}
            locale={{ emptyText: `waiting for Bottles...` }}
            pagination={{
              total: mine ? filteredFalgenes.length : totalSupply,
              defaultPageSize: perPage,
              defaultCurrent: page,
              onChange: currentPage => {
                setPage(currentPage - 1);
                console.log(currentPage);
              },
              showTotal: (total, range) =>
                `${range[0]}-${range[1]} of ${mine ? filteredFalgenes.length : totalSupply} items`,
            }}
            loading={loadingFalgene}
            dataSource={filteredFalgenes ? filteredFalgenes : []}
            renderItem={item => {
              const id = item.id;

              return (
                <List.Item key={id}>
                  <Card
                    title={
                      <div>
                        <span style={{ fontSize: 18, marginRight: 8 }}>{item.name ? item.name : `Bottle #${id}`}</span>
                        <Button
                          shape="circle"
                          onClick={() => {
                            updateOneFalgene(id);
                          }}
                          icon={<RedoOutlined />}
                        />
                      </div>
                    }
                  >
                    <a
                      href={`${blockExplorer}token/${readContracts[FalgeneContract] && readContracts[FalgeneContract].address
                        }?a=${id}`}
                      target="_blank"
                    >
                      <img src={item.image && item.image} alt={"Bottle #" + id} width="100" />
                    </a>
                    {item.owner &&
                      item.owner.toLowerCase() == readContracts[FalgeneContract].address.toLowerCase() ? (
                      <div>{item.description}</div>
                    ) : (
                      <div>
                        <Address
                          address={item.owner}
                          ensProvider={mainnetProvider}
                          blockExplorer={blockExplorer}
                          fontSize={16}
                        />
                      </div>
                    )}
                    {address && item.owner == address.toLowerCase() && (
                      <>
                        {item.attributes[0].value < 4 ? (
                          <>
                            <Button
                              type="primary"
                              style={{ marginRight: 2, marginBottom: 2 }}
                              onClick={async () => {
                                try {
                                  const txCur = await tx(writeContracts[FalgeneContract].sip(id));
                                  await txCur.wait();
                                  updateOneFalgene(id);
                                } catch (e) {
                                  console.log("sip failed", e);
                                }
                              }}
                            >
                              Sip
                            </Button>
                            <Popover
                              content={() => {
                                return pour(id);
                              }}
                              title="Pour Water"
                            >
                              <Button style={{ marginRight: 2, marginBottom: 2 }} type="primary">Pour</Button>
                            </Popover>
                            <Button
                              type="primary"
                              style={{ marginRight: 2, marginBottom: 2 }}
                              onClick={async () => {
                                if (DEBUG) console.log("POWDER PRICE", pricePowder.toNumber());
                                try {
                                  const txCur = await tx(writeContracts[FalgeneContract].addPowder(id, { value: pricePowder }));
                                  await txCur.wait();
                                  updateOneFalgene(id);
                                } catch (e) {
                                  console.log("Powder failed", e);
                                }
                              }}
                            >
                              Powder
                            </Button>
                          </>
                        ) : (
                          <Button
                            type="primary"
                            style={{ marginRight: 2, marginBottom: 2 }}
                            onClick={async () => {
                              if (DEBUG) console.log("REFILL PRICE", priceToRefill.toNumber());
                              try {
                                const txCur = await tx(writeContracts[FalgeneContract].refill(id, { value: priceToRefill }));
                                await txCur.wait();
                                updateOneFalgene(id);
                              } catch (e) {
                                console.log("Refill failed", e);
                              }
                            }}
                          >
                            Refill
                          </Button>
                        )}
                        <Popover
                          content={() => {
                            return sendForm(id);
                          }}
                          title="Send it:"
                        >
                          <Button style={{ marginRight: 2, marginBottom: 2 }} type="primary">Send it!</Button>
                        </Popover>
                      </>
                    )}
                  </Card>
                </List.Item>
              );
            }}
          />
        </div>
      )}
    </div>
  );
}

export default Falgene;
