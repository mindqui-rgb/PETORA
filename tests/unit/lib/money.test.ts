import { describe, it, expect } from "vitest";
import {
  roundMoney,
  roundMoneyString,
  formatRupiah,
  parseRupiah,
  calculateLineTotal,
  calculateGrandTotal,
  calculateSubtotal,
  addMoney,
  subtractMoney,
  multiplyMoney,
  percentDiscount,
  isNonNegative,
} from "@/lib/money";

describe("roundMoney", () => {
  it("rounds half-up correctly for positive numbers", () => {
    expect(roundMoney(1250.5)).toBe(1251);
    expect(roundMoney(1250.4)).toBe(1250);
    expect(roundMoney(1251.5)).toBe(1252);
    expect(roundMoney(0.5)).toBe(1);
    expect(roundMoney(0)).toBe(0);
  });

  it("throws for non-finite values", () => {
    expect(() => roundMoney(Infinity)).toThrow();
    expect(() => roundMoney(NaN)).toThrow();
  });
});

describe("roundMoneyString", () => {
  it("rounds decimal strings correctly", () => {
    expect(roundMoneyString("1250.5")).toBe("1251");
    expect(roundMoneyString("1250.4")).toBe("1250");
    expect(roundMoneyString("1251.5")).toBe("1252");
  });
});

describe("formatRupiah", () => {
  it("formats numbers as Rupiah", () => {
    expect(formatRupiah(1250000)).toBe("Rp 1.250.000");
    expect(formatRupiah(0)).toBe("Rp 0");
  });

  it("formats string inputs", () => {
    expect(formatRupiah("1250000")).toBe("Rp 1.250.000");
  });

  it("handles invalid inputs", () => {
    expect(formatRupiah("invalid")).toBe("Rp 0");
  });
});

describe("parseRupiah", () => {
  it("parses formatted Rupiah strings", () => {
    expect(parseRupiah("Rp 1.250.000")).toBe(1250000);
    expect(parseRupiah("1250000")).toBe(1250000);
  });
});

describe("calculateLineTotal", () => {
  it("calculates line total with discount", () => {
    expect(calculateLineTotal("100000", "10000")).toBe("90000");
  });

  it("throws when discount exceeds gross", () => {
    expect(() => calculateLineTotal("100000", "150000")).toThrow();
  });
});

describe("calculateGrandTotal", () => {
  it("sums line totals", () => {
    expect(calculateGrandTotal(["100000", "50000"])).toBe("150000");
  });
});

describe("calculateSubtotal", () => {
  it("sums line gross amounts", () => {
    expect(calculateSubtotal(["100000", "50000"])).toBe("150000");
  });
});

describe("addMoney", () => {
  it("adds two amounts", () => {
    expect(addMoney("100.00", "50.00")).toBe("150.00");
  });
});

describe("subtractMoney", () => {
  it("subtracts two amounts", () => {
    expect(subtractMoney("100.00", "50.00")).toBe("50.00");
  });
});

describe("multiplyMoney", () => {
  it("multiplies price by quantity", () => {
    expect(multiplyMoney("10000", 3)).toBe("30000.00");
  });
});

describe("percentDiscount", () => {
  it("calculates percentage discount", () => {
    expect(percentDiscount("100000", 10)).toBe("10000.00");
    expect(percentDiscount("100000", 10.01)).toBe("10010.00");
  });
});

describe("isNonNegative", () => {
  it("returns true for non-negative values", () => {
    expect(isNonNegative("100")).toBe(true);
    expect(isNonNegative(0)).toBe(true);
  });

  it("returns false for negative values", () => {
    expect(isNonNegative("-100")).toBe(false);
  });
});