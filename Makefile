default: run

run:
	@echo "Running the program..."
	@docker compose up -d

.PHONY: test

test:
	@find . -type f -name "*_test.lua" | while read file; do \
	    echo "Running: $$file"; \
	    luajit "$$file"; \
	    exit_code=$$?; \
	    if [ $$exit_code -ne 0 ]; then \
	        echo "❌ Test failed: $$file (exit code: $$exit_code)"; \
	        exit $$exit_code; \
	    fi; \
	done

test-e2e:
	@go test -v ./...