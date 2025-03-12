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
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose --profile memory_leak up --build --abort-on-container-exit --no-log-prefix

lint:
	luacheck --std ngx_lua ./lib/
	luacheck -g ./test/