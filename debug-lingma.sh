#!/bin/bash
echo "=== Debug Lingma Wrapper ==="
echo "Current directory: $(pwd)"
echo "DASHSCOPE_API_KEY from env: $DASHSCOPE_API_KEY"
echo "LINGMA_API_KEY from env: $LINGMA_API_KEY"

# Test .env file reading
if [ -f ".env" ]; then
    echo ".env file exists"
    DASHSCOPE_KEY=$(grep "^DASHSCOPE_API_KEY=" .env | cut -d'=' -f2- | tr -d '"')
    echo "Extracted DASHSCOPE_API_KEY from .env: $DASHSCOPE_KEY"
else
    echo ".env file does not exist"
fi

# Test Python script directly
echo "=== Testing Python script directly ==="
python lingma-real.py quest --prompt "direct python test" --output harness/tasks/direct-python.txt

# Test through wrapper
echo "=== Testing through lingma wrapper ==="
./lingma quest --prompt "wrapper test" --output harness/tasks/wrapper-test.txt

echo "=== Checking output files ==="
ls -la harness/tasks/