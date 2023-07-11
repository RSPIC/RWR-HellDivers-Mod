float NormalizedConcaveCurve(float x,float a,float center = 1){
    return (-pow(a,x) + 1)/(-pow(a,center) + 1);
}

// --------------------------------------------
bool isNumeric(string s)
{
	for(uint i = 0; i < s.length(); i++)
	{
        
        string a = s.substr(i,1);
		if (
           a != "0" 
        && a != "1"
        && a != "2"
        && a != "3"
        && a != "4"
        && a != "5"
        && a != "6"
        && a != "7"
        && a != "8"
        && a != "9"
        )
		{
			return false;
		}
	}
	return true;
}