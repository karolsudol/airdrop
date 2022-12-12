const MAX_SUPPLY = 100 * 10 ** 18;
const MAX_PER_MINT = 10 * 10 ** 18;

async function main() {
  console.log(MAX_SUPPLY.toString());
  console.log(MAX_PER_MINT.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
