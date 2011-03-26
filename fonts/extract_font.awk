BEGIN {
	line = 0
}

/^STARTCHAR/, /^ENDCHAR/ {
	if ($1 == "STARTCHAR")
	{
		printf $2 "\t"
		line = 1
	}
	else if ($1 == "ENDCHAR")
	{
		printf "\n"
		line = 0
	}
	else if ($1 == "ENCODING")
	{
		printf $2 " "
	}
	else if ($1 == "BITMAP")
	{
		line = 2
	}
	else if( line == 2 )
	{
		printf $1 " "
	}
}

