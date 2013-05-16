
all:
	@echo "Building \`epiece_nif' module..."
	@gcc -fPIC -shared -o epiece_nif.so epiece_nif.c -I/opt/erlang_otp/current/usr/include
	@erlc *.erl

clean:
	@echo "Cleaning up \`epiece_nif' module..."
	@rm -f *.beam *.so

