use Data::Dumper;
use warnings;
use FindBin;                 # locate this script
use griddb_perl;
use Time::Local 'timegm';

#Get StoreFactory object
my $factory = griddb_perl::StoreFactory::get_instance();

#Get GridStore object
my $gridstore = $factory->get_store({"host" => $ARGV[0], "port" => int($ARGV[1]), "cluster_name" => $ARGV[2], "username" => $ARGV[3], "password" => $ARGV[4]});

#Get TimeSeries
#Reuse TimeSeries and data from sample 2
my $ts = $gridstore->get_container("point01");

#Create normal query to get all row where active = FAlSE and voltage > 50
my $query = $ts->query("select * from point01 where not active and voltage > 50");
my $rs = $query->fetch(0);

#Access each returned column 
while ($rs->has_next()){
    my @data = $rs->next();
	$sec = $data[0][0];
	$min = $data[0][1];
	$hour = $data[0][2];
	$day = $data[0][3];
	$mon = $data[0][4];
	$year = $data[0][5];
	#print $sec, $min, $hour, $day, $mon, $year, "\n";

    my $timestamp = timegm($sec, $min, $hour, $day, $mon, $year);
    my $griddbTimestamp = griddb_perl::TimestampUtils::get_time_millis($timestamp);

    #Perform aggregation query to get average value 
    #during 10 minutes later and 10 minutes earlier from this point
    my $aggCommand = "select AVG(voltage) from point01 where timestamp > TIMESTAMPADD(MINUTE, TO_TIMESTAMP_MS($griddbTimestamp), -10) AND timestamp < TIMESTAMPADD(MINUTE, TO_TIMESTAMP_MS($griddbTimestamp), 10)";
    my $aggQuery = $ts->query($aggCommand);
    my $aggRs = $aggQuery->fetch();
    
    #Access each returned column 
    while ($aggRs->has_next()){
        #Get aggregation result
        my $aggResult = $aggRs->next();
		my $avgVoltage = $aggResult->get($griddb_perl::GS_TYPE_DOUBLE);
		print("[Timestamp = $griddbTimestamp] Average voltage = $avgVoltage \n");
    }
}
