import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="https://oe40.me" target="_blank" rel="noopener noreferrer">
      <PageHeader title="🚰 Bottles" subTitle="Staying Hydrated!" style={{ cursor: "pointer" }} />
    </a>
  );
}
