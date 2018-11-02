use Data::Dumper;
use warnings;
use FindBin;                 # locate this script
use griddb_perl;

#Get StoreFactory object
my $factory = griddb_perl::StoreFactory::get_instance();

#Get GridStore object
my $gridstore = $factory->get_store({"host" => $ARGV[0], "port" => int($ARGV[1]), "cluster_name" => $ARGV[2], "username" => $ARGV[3], "password" => $ARGV[4]});

#Create Collection
my $conInfo = griddb_perl::ContainerInfo->new("point01", [["timestamp", $griddb_perl::GS_TYPE_TIMESTAMP], ["active", $griddb_perl::GS_TYPE_BOOL], ["voltage", $griddb_perl::GS_TYPE_DOUBLE]], $griddb_perl::GS_CONTAINER_TIME_SERIES, 1);

#Put Collection is "point01"
#$gridstore->drop_container("point01");
my $ts = $gridstore->put_container($conInfo);

#Date time in Array
my @timeArray = gmtime();
#print Dumper \@timeArray;

#Put row: timestamp is Array
$ts->put([\@timeArray, 0, 100]);

#Create normal query for range of timestamp from 6 hours ago to now
my $query = $ts->query("select * where timestamp > TIMESTAMPADD(HOUR, NOW(), -6)");
my $rs = $query->fetch();

#Access each returned column 
while ($rs->has_next()){
	my @data = $rs->next();
	print Dumper $data[0];	#Timestamp is array
	my $active = $data[1];
	my $voltage = $data[2];
	print("Active=$active Voltage=$voltage\n");
}
