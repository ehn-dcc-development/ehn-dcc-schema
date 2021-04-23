SCHEMATA=	DGC.schema.json \
		DGC.Core.Types.schema.json \
		DGC.Types.schema.json
MERGED=		DGC-all-schemas-combined.json

AJV=		./node_modules/.bin/ajv -c ajv-formats --spec=draft2020


test:: compile validate-examples check-formatting

merge: $(MERGED)

compile::
	@echo "Compiling schemata..."
	-$(AJV) compile -r "DGC.*.schema.json" -s "DGC.schema.json"

check-formatting::
	@echo "Checking JSON formatting..."
	@for file in $(SCHEMATA) Lookup-tables/*.json examples/*.json; do \
		jq . <$$file >$$file.tmp; \
		if ! cmp $$file $$file.tmp; then \
			echo "Please reformat $$file"; \
		fi; \
		rm $$file.tmp; \
	done

validate-examples::
	-$(AJV) validate -r "DGC.*.schema.json" -s "DGC.schema.json" -d "examples/*.json"

$(MERGED): $(SCHEMATA)
	python3 merge.py $(SCHEMATA) | jq . > $@
	-$(AJV) compile -s $@
	-$(AJV) validate -s $@ -d "examples/*.json"

reformat::
	for file in *.json Lookup-tables/*.json; do jq . <$$file >$$file.tmp && mv $$file.tmp $$file; done

install-ajv:
	npm install ajv ajv-cli ajv-formats

clean:
	rm -f $(MERGED)
