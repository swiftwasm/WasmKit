python.exe .\Vendor\checkout-dependency wasi-testsuite
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python.exe -m pip install -r .\Vendor\wasi-testsuite\test-runner\requirements.txt
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python.exe .\IntegrationTests\WASI\run-tests.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
