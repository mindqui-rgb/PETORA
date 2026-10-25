/**
 * Money utilities for Indonesian Rupiah.
 * All amounts are stored as NUMERIC(14,2) strings in the database.
 * Transaction rounding uses half-up to the nearest rupiah (K11).
 */

/**
 * Rounds a decimal number to the nearest integer using half-up rounding.
 * @param value - The value to round
 * @returns The rounded integer
 */
export function roundMoney(value: number): number {
  if (!Number.isFinite(value)) {
    throw new Error("roundMoney: value must be a finite number");
  }
  return Math.round(value);
}

/**
 * Rounds a decimal string to the nearest integer using half-up rounding.
 * @param value - The decimal string to round
 * @returns The rounded integer as a string
 */
export function roundMoneyString(value: string): string {
  const num = Number(value);
  if (!Number.isFinite(num)) {
    throw new Error("roundMoneyString: value must be a valid decimal string");
  }
  return String(Math.round(num));
}

/**
 * Adds two decimal strings.
 * @param a - First amount
 * @param b - Second amount
 * @returns Sum as string
 */
export function addMoney(a: string, b: string): string {
  const result = Number(a) + Number(b);
  return result.toFixed(2);
}

/**
 * Subtracts two decimal strings.
 * @param a - Minuend
 * @param b - Subtrahend
 * @returns Difference as string
 */
export function subtractMoney(a: string, b: string): string {
  const result = Number(a) - Number(b);
  return result.toFixed(2);
}

/**
 * Multiplies a decimal string by a quantity.
 * @param unitPrice - Unit price as string
 * @param quantity - Quantity as number
 * @returns Product as string
 */
export function multiplyMoney(unitPrice: string, quantity: number): string {
  const result = Number(unitPrice) * quantity;
  return result.toFixed(2);
}

/**
 * Calculates percentage discount.
 * @param amount - Base amount as string
 * @param percent - Discount percentage (0-100)
 * @returns Discount amount as string
 */
export function percentDiscount(amount: string, percent: number): string {
  const result = Number(amount) * (percent / 100);
  return result.toFixed(2);
}

/**
 * Calculates fixed amount discount.
 * @param amount - Discount amount as string
 * @returns Discount amount as string
 */
export function amountDiscount(amount: string): string {
  return amount;
}

/**
 * Formats a number as Indonesian Rupiah.
 * @param amount - Amount to format
 * @returns Formatted string like "Rp 1.250.000"
 */
export function formatRupiah(amount: number | string): string {
  const num = typeof amount === "string" ? Number(amount) : amount;
  if (!Number.isFinite(num)) {
    return "Rp 0";
  }
  const formatted = Math.round(num)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  return `Rp ${formatted}`;
}

/**
 * Parses a formatted Rupiah string back to a number.
 * @param value - Formatted string like "Rp 1.250.000"
 * @returns Parsed number
 */
export function parseRupiah(value: string): number {
  const cleaned = value.replace(/[^0-9]/g, "");
  return Number(cleaned) || 0;
}

/**
 * Validates that a money amount is non-negative.
 * @param amount - Amount to validate
 * @returns true if non-negative
 */
export function isNonNegative(amount: string | number): boolean {
  const num = typeof amount === "string" ? Number(amount) : amount;
  return Number.isFinite(num) && num >= 0;
}

/**
 * Calculates line total with discount (half-up rounding).
 * @param lineGross - Line gross amount (qty * unit_price)
 * @param lineDiscount - Line discount amount
 * @returns Line total rounded half-up
 */
export function calculateLineTotal(lineGross: string, lineDiscount: string): string {
  const gross = Number(lineGross);
  const discount = Number(lineDiscount);
  if (discount > gross) {
    throw new Error("calculateLineTotal: discount cannot exceed gross");
  }
  const total = Math.round(gross - discount);
  return String(total);
}

/**
 * Calculates grand total from line totals.
 * @param lineTotals - Array of line total strings
 * @returns Grand total as string
 */
export function calculateGrandTotal(lineTotals: string[]): string {
  const sum = lineTotals.reduce((acc, val) => acc + Number(val), 0);
  return String(Math.round(sum));
}

/**
 * Calculates subtotal from line gross amounts.
 * @param lineGrosses - Array of line gross strings
 * @returns Subtotal as string
 */
export function calculateSubtotal(lineGrosses: string[]): string {
  const sum = lineGrosses.reduce((acc, val) => acc + Number(val), 0);
  return String(Math.round(sum));
}