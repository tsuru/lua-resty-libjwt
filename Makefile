default: run

run:
	@echo "Running the program..."
	@docker compose --profile dev up --build

.PHONY: test

test.unit:
	@find . -type f -name "*_test.lua" | while read file; do \
	    echo "Running: $$file"; \
	    luajit "$$file"; \
	    exit_code=$$?; \
	    if [ $$exit_code -ne 0 ]; then \
	        echo "❌ Test failed: $$file (exit code: $$exit_code)"; \
	        exit $$exit_code; \
	    fi; \
	done

test.e2e:
	@go test -v ./...

test.memory_leak:
	docker build -t libjwt-memory-leak-tests --platform linux/amd64 -f .memory_leak/Dockerfile .
	docker run --rm --name libjwt-memory-leak-tests libjwt-memory-leak-tests
lint:
	luacheck --std ngx_lua ./lib/
	luacheck -g ./test/