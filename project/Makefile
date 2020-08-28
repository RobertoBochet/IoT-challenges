.PHONY: all clean sensor_node gateway network_server

all: sensor_node gateway network_server

sensor_node: ./sensor_node/coreAppC.nc ./sensor_node/coreC.nc
	make telosb -C ./sensor_node

gateway: gateway/coreAppC.nc gateway/coreC.nc
	make telosb -C ./gateway

network_server: network_server/coreAppC.nc network_server/coreC.nc
	make telosb -C ./network_server

clean:
	-rm -fr ./sensor_node/build
	-rm -fr ./gateway/build
	-rm -fr ./network_server/build