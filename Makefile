BASE_URL=	"https://id.uvci.eu"

SCHEMATA=	DCC.schema.json \
		DCC.Core.Types.schema.json \
		DCC.Types.schema.json \
		DCC.ValueSets.schema.json

MERGED_SCHEMA=	DCC.combined-schema.json
MERGED_ID=	"$(BASE_URL)/$(MERGED_SCHEMA)"

JSON_FILES=	*.json \
		examples/vaccination/*.json \
		examples/test/*.json \
		examples/recovery/*.json \
		test/invalid/*.json \
		test/valid/*.json \

AJV=		./node_modules/.bin/ajv -c ajv-formats --spec=draft2020 --strict=false


# validate all DCC JSON files against the merged schema:
validate-all:: compile $(MERGED_SCHEMA)
	$(AJV) test -s $(MERGED_SCHEMA) -d "examples/vaccination/*.json" --valid
	$(AJV) test -s $(MERGED_SCHEMA) -d "examples/recovery/*.json" --valid
	$(AJV) test -s $(MERGED_SCHEMA) -d "examples/test/*.json" --valid
	$(AJV) test -s $(MERGED_SCHEMA) -d "test/valid/*.json" --valid
	$(AJV) test -s $(MERGED_SCHEMA) -d "test/invalid/*.json" --invalid

compile::
	@echo "Compiling schemata..."
	$(AJV) compile -r "DCC.*.schema.json" -s "DCC.schema.json"

check-formatting::
	@echo "Checking JSON formatting..."
	@for file in $(JSON_FILES); do \
		jq . <$$file >$$file.tmp; \
		if ! cmp $$file $$file.tmp; then \
			echo "Please reformat $$file"; \
			rm $$file.tmp; \
			exit 1; \
		else \
			rm $$file.tmp; \
		fi; \
	done

# validate valid example DCC JSON files against the unmerged schema:
validate-examples:
	$(AJV) validate -r "DCC.*.schema.json" -s "DCC.schema.json" -d "examples/vaccination/*.json"
	$(AJV) validate -r "DCC.*.schema.json" -s "DCC.schema.json" -d "examples/recovery/*.json"
	$(AJV) validate -r "DCC.*.schema.json" -s "DCC.schema.json" -d "examples/test/*.json"

# validate valid test DCC JSON files against the unmerged schema:
validate-valid-tests:
	$(AJV) validate -r "DCC.*.schema.json" -s "DCC.schema.json" -d "test/valid/*.json"
	
# validate invalid test DCC JSON files against the unmerged schema:
validate-invalid-tests:
	$(AJV) test -r "DCC.*.schema.json" -s "DCC.schema.json" -d "test/invalid/*.json" --invalid

# merge the schemata:
$(MERGED_SCHEMA): $(SCHEMATA)
	python3 merge.py --id $(MERGED_ID) $(SCHEMATA) | jq . > $@
	$(AJV) compile -s $@

reformat::
	for file in $(JSON_FILES); do echo $$file; jq . <$$file >$$file.tmp && mv $$file.tmp $$file; done

install-ajv:
	npm install ajv ajv-cli ajv-formats

clean:
	rm -f $(MERGED_SCHEMA)

