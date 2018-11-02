use Data::Dumper;
use warnings;
use FindBin;                 	# locate this script
use griddb_perl;

my $byte_array = "ABCDEFGHIJ";
my $update = 1; 				#true

eval {
	#Get StoreFactory object
	my $factory = griddb_perl::StoreFactory::get_instance();

	#Get GridStore object
	my $gridstore = $factory->get_store({"host" => $ARGV[0], "port" => int($ARGV[1]), "cluster_name" => $ARGV[2], "username" => $ARGV[3], "password" => $ARGV[4]});

	#Create Collection
	my $conInfo = griddb_perl::ContainerInfo->new("col01", [["name", $griddb_perl::GS_TYPE_STRING], ["status", $griddb_perl::GS_TYPE_BOOL], ["count", $griddb_perl::GS_TYPE_LONG], ["lob", $griddb_perl::GS_TYPE_BLOB]], $griddb_perl::GS_CONTAINER_COLLECTION, 1);

	#Put Collection is "col01"
	#$gridstore->drop_container("col01");
	my $col = $gridstore->put_container($conInfo);

	#Change auto commit mode to false
	$col->set_auto_commit(0);

	#Set an index on the Row-key Column
	$col->create_index("name", $griddb_perl::GS_INDEX_FLAG_DEFAULT);

	#Set an index on the Column
	$col->create_index("count", $griddb_perl::GS_INDEX_FLAG_DEFAULT);

	#Put row: RowKey is "name01"
	$col->put(["name01", 0, 1, $byte_array]);
	$col->remove("name01");

	#Put row: RowKey is "name02"
	$col->put(["name02", 0, 1, $byte_array]);
	$col->commit();

	#Get row: RowKey is "name02"
	#@mlist = 
	$col->get("name02");
	#print Dumper \@mlist;

	#Execute query
	my $query = $col->query("select *");
	my $rs = $query->fetch($update);

	#Access each returned column 
	while ($rs->has_next()){
		my @data = $rs->next();
		$data[2] = $data[2] + 1;
		print Dumper \@data;

    	$rs->update(\@data);
	}
	
	#End transaction
	$col->commit();

	1; 	# always return true to indicate success
} or do {
	print "ERROR\n";
    for ( $i = 0; $i < $@->get_error_stack_size();$i = $i + 1) {
        print("[$i]\n");
		my $e = $@->get_error_code($i);
        warn("$e\n");
		$e = $@->get_message($i);
        warn("$e\n");
    }
    my $e = $@->what();
    warn("$e\n");
}