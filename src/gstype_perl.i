/*
    Copyright (c) 2018 TOSHIBA Digital Solutions Corporation.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
%{
#include <ctime>
#include <limits>
%}

//Wrap pair of get/set methods attribute
%include <attribute.i>
//Read only attribute Container::type
%attribute(griddb::Container, int, type, get_type);
//Read only attribute GSException::is_timeout
%attribute(griddb::GSException, bool, is_timeout, is_timeout);
//Read only attribute Store::partition_info
%newobject griddb::Store::partition_info;
%attribute(griddb::Store, griddb::PartitionController*, partition_info, partition_info);
//Read only attribute PartitionController::partition_count
%attribute(griddb::PartitionController, int, partition_count, get_partition_count);
//Read only attribute RowKeyPredicate::partition_count
%attribute(griddb::RowKeyPredicate, GSType, key_type, get_key_type);
//Read only attribute RowSet::size
%attribute(griddb::RowSet, int32_t, size, size);
//Read only attribute RowSet::type
%attribute(griddb::RowSet, GSRowSetType, type, type);
//Read and write attribute ContainerInfo::name
%attribute(griddb::ContainerInfo, GSChar*, name, get_name, set_name);
//Read and write attribute ContainerInfo::type
%attribute(griddb::ContainerInfo, int, type, get_type, set_type);
//Read and write attribute ContainerInfo::rowKeyAssign
%attribute(griddb::ContainerInfo, bool, row_key, get_row_key_assigned, set_row_key_assigned);
//Read only attribute ExpirationInfo::time
%attribute(griddb::ExpirationInfo, int, time, get_time, set_time);
//Read and write attribute ExpirationInfo::unit
%attribute(griddb::ExpirationInfo, GSTimeUnit, unit, get_time_unit, set_time_unit);
//Read and write attribute ExpirationInfo::divisionCount
%attribute(griddb::ExpirationInfo, int, division_count, get_division_count, set_division_count);

//Define Timestamp constant
#define PERL_DATETIME_SEC		0
#define PERL_DATETIME_MIN		1
#define PERL_DATETIME_HOUR		2
#define PERL_DATETIME_MDAY		3
#define PERL_DATETIME_MON		4
#define PERL_DATETIME_YEAR		5
#define PERL_DATETIME_WDAY		6
#define PERL_DATETIME_YDAY		7
#define PERL_DATETIME_ISDST		8
#define UTC_TIMESTAMP_MAX 		253402300799.999

/**
 * Support convert timestamp from Griddb to target language
 */
%fragment("convertTimestampToSV", "header") {
	static SV* convertTimestampToSV(GSTimestamp* timestamp, bool timestamp_to_float = true) {
		SV* dateTime;
		// GridDB use UTC datetime => use the string output from gsFormatTime to convert to UTC datetime
		if (timestamp_to_float) {
			dateTime = newSVnv(((double)(*timestamp)) / 1000);
			return dateTime;
		}

		// Read Time from GridDB
		size_t bufSize = 100;
		static GSChar strBuf[100] = {0};
		gsFormatTime(*timestamp, strBuf, bufSize);

		// Date format is YYYY-MM-DDTHH:mm:ss.sssZ
		int year;
		int month;
		int day;
		int hour;
		int minute;
		int second;
		int miliSecond;
		int microSecond;
		sscanf(strBuf, "%d-%d-%dT%d:%d:%d.%dZ", &year, &month, &day, &hour, &minute, &second, &miliSecond);
		microSecond = miliSecond * 1000;
		if (year >= 1900) {
			year = year - 1900;
		}

		// Convert to array
		AV *dateTimeArr = newAV();
		av_store(dateTimeArr, PERL_DATETIME_SEC, newSViv(second));
		av_store(dateTimeArr, PERL_DATETIME_MIN, newSViv(minute));
		av_store(dateTimeArr, PERL_DATETIME_HOUR, newSViv(hour));
		av_store(dateTimeArr, PERL_DATETIME_MDAY, newSViv(day));
		av_store(dateTimeArr, PERL_DATETIME_MON, newSViv(month));
		av_store(dateTimeArr, PERL_DATETIME_YEAR, newSViv(year));
		av_store(dateTimeArr, PERL_DATETIME_WDAY, newSViv(0));
		av_store(dateTimeArr, PERL_DATETIME_YDAY, newSViv(0));
		av_store(dateTimeArr, PERL_DATETIME_ISDST, newSViv(0));
		dateTime = newRV_noinc((SV*)dateTimeArr);

		return (SV*)dateTime;
	}
}

/*
* fragment to support converting data for GSRow
*/
%fragment("convertFieldToSV", "header", fragment = "convertTimestampToSV") {
	static void convertFieldToSV(SV* arr, griddb::Field &field, bool timestamp_to_float = true) {
		int listSize, i;
		void* arrayPtr;
		SV* dateTime;
		switch (field.type) {
        	case GS_TYPE_BLOB:
        		sv_setpvn((SV*)arr, (const char*)field.value.asBlob.data, field.value.asBlob.size);
        		return;
        	case GS_TYPE_BOOL:
        		sv_setiv(arr, (IV) field.value.asBool);
        		return;
        	case GS_TYPE_INTEGER:
        		sv_setiv(arr, (IV) field.value.asInteger);
        		return;
        	case GS_TYPE_LONG:
        		sv_setiv(arr, (IV) field.value.asInteger);
        		return;
        	case GS_TYPE_FLOAT:
        		sv_setnv(arr, (NV) field.value.asFloat);
        		return;
        	case GS_TYPE_DOUBLE:
        		sv_setnv(arr, (NV) field.value.asDouble);
        		return;
        	case GS_TYPE_STRING:
        		sv_setpv((SV*)arr, (const char*)field.value.asString);
        		return;
        	case GS_TYPE_TIMESTAMP:
        		dateTime = convertTimestampToSV(&field.value.asTimestamp, timestamp_to_float);
        		sv_setsv(arr, dateTime);
        		return;
        	case GS_TYPE_NULL:
        		return;
        	case GS_TYPE_BYTE:
        		sv_setiv(arr, (IV) field.value.asByte);
        		return;
        	case GS_TYPE_SHORT:
        		sv_setiv(arr, (IV) field.value.asShort);
        		return;
        	case GS_TYPE_INTEGER_ARRAY:
        		printf("return GS_TYPE_INTEGER_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asIntegerArray.size;
            arrayPtr = (void*) field.value.asIntegerArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asInteger;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyInt_FromLong(*((int32_t *)arrayPtr + i)));
            }
            return list;
*/
        	case GS_TYPE_STRING_ARRAY:
        		printf("return GS_TYPE_STRING_ARRAY");
        		return;
            /*
            GSChar** arrString;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asStringArray.size;
            arrString = (GSChar**) field.value.asStringArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrString = (GSChar**) field.value.asArray.elements.asString;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, convertStrToObj(arrString[i]));
            }
            return list;
*/
        	case GS_TYPE_BOOL_ARRAY:
        		printf("return GS_TYPE_BOOL_ARRAY");
        		return;
            /*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asBoolArray.size;
            arrayPtr = (void*) field.value.asBoolArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asBool;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyBool_FromLong(*((bool *)arrayPtr + i)));
            }
            return list;
            */
        	case GS_TYPE_BYTE_ARRAY:
        		printf("return GS_TYPE_BYTE_ARRAY");
        		return;
            /*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asByteArray.size;
            arrayPtr = (void*) field.value.asByteArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asByte;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyInt_FromLong(*((int8_t *)arrayPtr + i)));
            }
            return list;
            */
        	case GS_TYPE_SHORT_ARRAY:
        		printf("return GS_TYPE_SHORT_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asShortArray.size;
            arrayPtr = (void*) field.value.asShortArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asShort;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyInt_FromLong(*((int16_t *)arrayPtr + i)));
            }
            return list;
            */
        	case GS_TYPE_LONG_ARRAY:
        		printf("return GS_TYPE_LONG_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asLongArray.size;
            arrayPtr = (void*) field.value.asLongArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asLong;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyLong_FromLong(*((int64_t *)arrayPtr + i)));
            }
            return list;
            */
        	case GS_TYPE_FLOAT_ARRAY:
        		printf("return GS_TYPE_FLOAT_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asFloatArray.size;
            arrayPtr = (void*) field.value.asFloatArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asFloat;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyFloat_FromDouble(static_cast<double>(*((float *)arrayPtr + i))));
            }
            return list;
            */
        	case GS_TYPE_DOUBLE_ARRAY:
        		printf("return GS_TYPE_DOUBLE_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asDoubleArray.size;
            arrayPtr = (void*) field.value.asDoubleArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asDouble;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, PyFloat_FromDouble(*((double *)arrayPtr + i)));
            }
            return list;
            */
        	case GS_TYPE_TIMESTAMP_ARRAY:
        		printf("return GS_TYPE_TIMESTAMP_ARRAY");
        		return;
        	/*
%#if GS_COMPATIBILITY_VALUE_1_1_106
            listSize = field.value.asTimestampArray.size;
            arrayPtr = (void*) field.value.asTimestampArray.elements;
%#else
            listSize = field.value.asArray.length;
            arrayPtr = (void*) field.value.asArray.elements.asTimestamp;
%#endif
            list = PyList_New(listSize);
            for (i = 0; i < listSize; i++) {
                PyList_SetItem(list, i, convertTimestampToObject(((GSTimestamp *)arrayPtr + i)));
            }
            return list;
            */
        	default:
        		printf("return GS_TYPE_DEFAULT");
        		return;
		}
	}
}


/**
 * Support convert type from SV to GSTimestamp: input in target language can be :
 * datetime, string or float
 */
%fragment("convertSVToGSTimestamp", "header") {
	static bool convertSVToGSTimestamp(SV* value, GSTimestamp* timestamp) {
		int year, month, day, hour, minute, second, milliSecond, microSecond;
		char* dateString;
		GSBool retConvertTimestamp;
	    char s[30];
		float floatTimestamp;

		if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {	//Check SV is Array
			// Input is Perl datetime array
			AV* dateArr = (AV*) SvRV(value);

			year = SvIV(*av_fetch(dateArr, PERL_DATETIME_YEAR, 0));
			if(year < 1900){	//Year in perl has format 1900 + xx
				year += 1900;
			}
			month = SvIV(*av_fetch(dateArr, PERL_DATETIME_MON, 0)) + 1;	//Month array start with 0 as January
			day = SvIV(*av_fetch(dateArr, PERL_DATETIME_MDAY, 0));
			hour = SvIV(*av_fetch(dateArr, PERL_DATETIME_HOUR, 0));
			minute = SvIV(*av_fetch(dateArr, PERL_DATETIME_MIN, 0));
			second = SvIV(*av_fetch(dateArr, PERL_DATETIME_SEC, 0));
			milliSecond = 0;
			//milliSecond = PyDateTime_DATE_GET_MICROSECOND(value)/1000;

			sprintf(s, "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", year, month, day, hour, minute, second, milliSecond);
			retConvertTimestamp = gsParseTime(s, timestamp);
			if (retConvertTimestamp == GS_FALSE) {
				return false;
			}
			return true;
		} else if (SvPOK(value)) {				//Check SV is String
			// Input is datetime string: ex
			dateString = (char *)SvPV(value, PL_na);
    	
			// Error when string len is too short
			if (strlen(dateString) < 19) {
				delete [] dateString;
				return false;
			}

			// Convert input string datetime (YYYY-MM-DDTHH:mm:ss:sssZ)
			// to griddb's string datetime (YYYY-MM-DDTHH:mm:ss.sssZ)
			dateString[19] = '.';
			retConvertTimestamp = gsParseTime(dateString, timestamp);
	        delete [] dateString;

			return (retConvertTimestamp == GS_TRUE);
		} else if (SvIOK(value)) {				//Check SV is Integer
			// Parse SV to Integer
			if (SvIV(value) > UTC_TIMESTAMP_MAX) {
				return false;
			}
			*timestamp = (GSTimestamp)(SvIV(value) * 1000);
			return true;
		} else if (SvNOK(value)) {				//Check SV is Double
			// Parse SV to Double
			if (SvNV(value) > UTC_TIMESTAMP_MAX) {
				return false;
			}
			*timestamp = (GSTimestamp)(SvNV(value) * 1000);
			return true;
		} else {
			// Invalid input
			return false;
		}
	}
}

/**
 * Support convert type from SV to Blob. input in target language can be :
 * byte array or string
 * Need to free data.
 */
%fragment("convertSVToBlob", "header") {
	static bool convertSVToBlob(SV* value, size_t* size, void** data) {
		SV** byteInArr;
		GSChar* blobData;

		//Check SV is array
		if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
			AV* arr = (AV*) SvRV(value);
			//Length of array = highest index + 1
			*size = (int)av_len(arr) + 1;
			if (*size > 0) {
				blobData = (GSChar*) malloc(sizeof(GSChar) * (*size));
				if (blobData == NULL) {
					return false;
				}
				int i = 0;
				memset(blobData, 0x0, sizeof(GSChar) * (*size));
				while (i < *size) {
					byteInArr = av_fetch(arr, i, 0);
					if (SvIOK(*byteInArr)) {
						blobData[i] = (GSChar) SvIV(*byteInArr);
					} else if (SvPOK(*byteInArr)) {
						blobData[i] = (GSChar) *SvPV(*byteInArr, PL_na);
					}
					i++;
				}
				*data = (void*) blobData;
			}

			return true;
		} else if (SvPOK(value)) {					//Check SV is string
			blobData = (char *)SvPV(value, PL_na);	//Convert SV to string
			*size = SvCUR(value);					//Get current length
			*data = (void*) blobData;
			return true;
		}
		return false;
	}
}

/**
 * Support covert Field from SV* to C Object with specific type
 */
%fragment("convertSVToFieldWithType", "header", fragment = "convertSVToBlob", fragment = "convertSVToGSTimestamp") {
    static bool convertSVToFieldWithType(griddb::Field &field, SV* value, GSType type) {
        char* tmpString = 0;
        bool convertResult;
        int tmpInt;
        long double tmpLongDouble;
        double tmpDouble;
        int length;
        field.type = type;
        if (value == NULL) {
            field.type = GS_TYPE_NULL;
            return true;
        }

        switch(type) {
            case (GS_TYPE_STRING):
                if (!SvPOK(value)) {
                    return false;
                }
            	tmpString = (char *)SvPV(value, PL_na);
                length = SvCUR(value);
                field.value.asString = (GSChar*) malloc(length * sizeof(GSChar) + 1);
                memcpy((void *)field.value.asString, tmpString, length * sizeof(GSChar) + 1);
                field.type = GS_TYPE_STRING;
                break;

            case (GS_TYPE_BOOL):
                field.value.asBool = SvTRUE(value);
                break;

			case (GS_TYPE_BYTE):
				if(!SvIV(value)){
					return false;
				}
                tmpInt = SvIV(value);
                if (tmpInt < std::numeric_limits<int8_t>::min() ||
                		tmpInt > std::numeric_limits<int8_t>::max()) {
                    return false;
                }
                field.value.asByte = (int8_t) tmpInt;
                break;
               
            case (GS_TYPE_SHORT):
				if(!SvIV(value)){
					return false;
				}
            	tmpInt = SvIV(value);
                if (tmpInt < std::numeric_limits<int16_t>::min() ||
                		tmpInt > std::numeric_limits<int16_t>::max()) {
                    return false;
                }
                field.value.asShort = (int16_t) tmpInt;
                break;

            case (GS_TYPE_INTEGER):
				if (!SvIV(value)) {
					return false;
				}
				field.value.asInteger = (int) SvIV(value);
                break;

            case (GS_TYPE_LONG):
				if (!SvIV(value)) {
					return false;
				}
                field.value.asLong = (long) SvIV(value);
                //Because swig function above not check overflow of long type.
                tmpDouble = SvNV(value);
                if (tmpDouble < double(std::numeric_limits<long>::min()) ||
                		tmpDouble > double(std::numeric_limits<long>::max())) {
                    return false;
                }
                break;

            case (GS_TYPE_FLOAT):
				if (!SvNV(value)) {
					return false;
				}
            	tmpDouble = SvNV(value);
                field.value.asFloat = tmpDouble;
                break;

            case (GS_TYPE_DOUBLE):
                tmpLongDouble = SvNV(value);
                field.value.asDouble = tmpLongDouble;
                break;

            case (GS_TYPE_TIMESTAMP):
                return convertSVToGSTimestamp(value, &field.value.asTimestamp);
                break;

            case (GS_TYPE_BLOB):
				convertResult = convertSVToBlob(value, &field.value.asBlob.size, (void**) &field.value.asBlob.data);
                if (!convertResult) {
                    return false;
                }
                break;
            case (GS_TYPE_STRING_ARRAY):
            case (GS_TYPE_GEOMETRY):
            case (GS_TYPE_INTEGER_ARRAY):
            case GS_TYPE_BOOL_ARRAY:
            case GS_TYPE_BYTE_ARRAY:
            case GS_TYPE_SHORT_ARRAY:
            case GS_TYPE_LONG_ARRAY:
            case GS_TYPE_FLOAT_ARRAY:
            case GS_TYPE_DOUBLE_ARRAY:
            case GS_TYPE_TIMESTAMP_ARRAY:
            default:
                //Not support for now
                return false;
        }
        return true;
    }
}

/**-------------------------------------GSException Class------------------------------------------------**/
/**
* Typemaps for throw GSException
*/
%typemap(throws) griddb::GSException %{
    sv_setsv(get_sv("@", GV_ADD), SWIG_NewPointerObj(SWIG_as_voidptr(&$1), $descriptor(griddb::GSException*), SWIG_POINTER_OWN)); SWIG_fail ;
%}

/**-------------------------------------StoreFactory Class------------------------------------------------**/
/**
* Typemaps for StoreFactory::set_properties(const GSPropertyEntry* props, int propsCount)
*/
%typemap(in) (const GSPropertyEntry* props, int propsCount)
(HE* tmpHE, HV* tmpHV) {
    if (SvTYPE(SvRV($input)) != SVt_PVHV) {
        croak("Expected a hash");
    }
    tmpHV = (HV*) SvRV($input);
    $2 = (int) (hv_iterinit(tmpHV));
    $1 = NULL;
    int i = 0;
    if ($2 > 0) {
        $1 = (GSPropertyEntry *) malloc($2*sizeof(GSPropertyEntry));
        if ($1 == NULL) {
            croak("Memory allocation error");
        }
        while ((tmpHE = hv_iternext(tmpHV)) != NULL) {
            $1[i].name = (char*) SvPV(HeSVKEY_force(tmpHE), PL_na);
            $1[i].value = (char*) SvPV(HeVAL(tmpHE), PL_na);
            i++;
        }
    }
}

%typemap(freearg) (const GSPropertyEntry* props, int propsCount) (int i = 0, int j = 0) {
    if ($1) {
        free((void *) $1);
    }
}

/**-------------------------------------ContainerInfo Class------------------------------------------------**/
/**
* Typemaps for ContainerInfo::init() function
*/
%typemap(in) (const GSColumnInfo* props, int propsCount)
(AV* colInfoArr, SV** tmpColInfo, AV* colInfo, SV** colInfoName, SV** colInfoType, SV** colInfoOpt, int colInfo_size = 0) {
	if (SvTYPE(SvRV($input)) != SVt_PVAV){
        croak("Expected GSColumnInfo array.");        
    }

    //Convert input parameter to array
    colInfoArr = (AV*) SvRV($input);
    $2 = (int)av_len(colInfoArr) + 1;
    $1 = NULL;
    if ($2 > 0) {
        $1 = (GSColumnInfo *) malloc($2*sizeof(GSColumnInfo));
        if($1 == NULL) {
            croak("Memory allocation error");
        }
        memset($1, 0x0, $2*sizeof(GSColumnInfo));
        int i = 0;
        while (i < $2) {
        	//Get GSColumnInfo of GSColumnInfo array in type AV
        	tmpColInfo = av_fetch(colInfoArr, i, 0);
            if (SvTYPE(SvRV(*tmpColInfo)) != SVt_PVAV){
                croak("Expected GSColumnInfo type.");
            }
            colInfo = (AV*) SvRV(*tmpColInfo);
            //Length of array = highest index + 1
            colInfo_size = (int)av_len(colInfo) + 1;
            //Check type of data of GSColumnInfo
            if ((colInfoName = av_fetch(colInfo, 0, 0)) && SvPOK(*colInfoName)) {
            	$1[i].name = (char *)SvPV(*colInfoName, PL_na);
            } else {
            	croak("Expected an String as name");
            }
            if ((colInfoType = av_fetch(colInfo, 1, 0)) && SvIOK(*colInfoType)) {
            	$1[i].type = (int) SvIV(*colInfoType);
            } else {
            	croak("Expected an Integer as type");
            }

%#if GS_COMPATIBILITY_SUPPORT_3_5
            if (colInfo_size == 2) {
            	if (i == 0) {
            		$1[i].options = GS_TYPE_OPTION_NOT_NULL;
            	} else if (i > 0) {
            		$1[i].options = GS_TYPE_OPTION_NULLABLE;
            	}
            } else if (colInfo_size == 3) {
            	colInfoOpt = av_fetch(colInfo, 2, 0);
            	if (!SvIOK(*colInfoOpt)) {
            		croak("Expected an Integer as option");
            	}
            	
            	$1[i].options = (int) SvIV(*colInfoOpt);
            	if ($1[i].options != GS_TYPE_OPTION_NULLABLE && $1[i].options != GS_TYPE_OPTION_NOT_NULL) {
            		croak("Invalid value for option");
            	}
            }
%#endif
            i++;
        }
    }
}

%typemap(typecheck) (const GSColumnInfo* props, int propsCount) {
    $1 = (SvROK($input) && SvTYPE(SvRV($input)) == SVt_PVAV) ? 1 : 0;
}

%typemap(freearg) (const GSColumnInfo* props, int propsCount) (int i) {
    if ($1) {
        free((void *) $1);
    }
}


/**
* Typemaps for Container::put(Row *rowContainer) function
*/
%typemap(in, fragment="convertSVToFieldWithType") (griddb::Row *rowContainer) 
(AV* rowObj, SV** rowAtt) {
	
	if (SvTYPE(SvRV($input)) != SVt_PVAV){
        croak("Expected Row array.");        
    }

    //Convert input parameter to array
	rowObj = (AV*) SvRV($input);
	
	//Length of array = highest index + 1
    int rowObjLen = (int)av_len(rowObj) + 1;

    $1 = new griddb::Row(rowObjLen);
    if ($1 == NULL) {
    	croak("Memory allocation error");
    }
    griddb::Field *tmpField = $1->get_field_ptr();
    if (rowObjLen != arg1->getColumnCount()) {
    	croak("num row is different with container info");
    }
    GSType* typeList = arg1->getGSTypeList();
    int i = 0;
    while (i < rowObjLen) {
        GSType type = typeList[i];
        rowAtt = av_fetch(rowObj, i, 0);
        if(!(convertSVToFieldWithType(tmpField[i], *rowAtt, type))) {
        	printf("Invalid value for column %d, type should be : %d\n", i, type);
        	SWIG_fail;
        }
        i++;
    }
}

%typemap(freearg) (griddb::Row *rowContainer) {
    if ($1) {
        delete $1;
    }
}


/*
* Typemaps for Container::get(Field* keyFields, Row *rowdata) function
* Typemaps for Container::remove(Field* keyFields) function
*/
%typemap(in, fragment = "convertSVToFieldWithType") (griddb::Field* keyFields)(griddb::Field field) {
    $1 = &field;
    if ($input == NULL) {
        $1->type = GS_TYPE_NULL;
    } else {
        GSType* typeList = arg1->getGSTypeList();
        GSType type = typeList[0];
        if (!convertSVToFieldWithType(*$1, $input, type)) {
        	croak("Can not convert to row field");
        }
    }
}

//%typemap(doc, name = "key") (griddb::Field* keyFields) "object";

%typemap(in, numinputs = 0) (griddb::Row *rowdata) {
    $1 = new griddb::Row();
    if ($1 == NULL) {
    	croak("Memory allocation error");
    }
}

%typemap(freearg) (griddb::Row *rowdata) {
    if ($1) {
        delete $1;
    }
}

%typemap(argout, fragment="convertFieldToSV") (griddb::Row *rowdata) {
	int count = $1->get_count();	//Array length of input
	
	//Read each col from input then convert to field & increase output stack argvi
    for (argvi = 0; argvi < count; argvi++) {
    	$result = sv_newmortal();	//Create the new SV no value
    	if($result == NULL){
    		croak("Memory allocation error");
    	}
    	convertFieldToSV($result, $1->get_field_ptr()[argvi], arg1->timestamp_output_with_float);
    }
}

/**-------------------------------------RowSet Class------------------------------------------------**/
/**
* Typemaps for RowSet::update(Row* row) function
*/
%typemap(in, fragment="convertSVToFieldWithType") (griddb::Row* row) 
(AV* rowObj, SV** rowAtt) {
	
	if (SvTYPE(SvRV($input)) != SVt_PVAV){
        croak("Expected Row array.");        
    }

    //Convert input parameter to array
	rowObj = (AV*) SvRV($input);
	
	//Length of array = highest index + 1
    int rowObjLen = (int)av_len(rowObj) + 1;

    $1 = new griddb::Row(rowObjLen);
    if ($1 == NULL) {
    	croak("Memory allocation error");
    }
    griddb::Field *tmpField = $1->get_field_ptr();
    if (rowObjLen != arg1->getColumnCount()) {
    	croak("num row is different with container info");
    }
    GSType* typeList = arg1->getGSTypeList();
    int i = 0;
    while (i < rowObjLen) {
        GSType type = typeList[i];
        rowAtt = av_fetch(rowObj, i, 0);
        if(!(convertSVToFieldWithType(tmpField[i], *rowAtt, type))) {
           croak(NULL);
        }
        i++;
    }
}

%typemap(freearg) (griddb::Row* row) {
    if ($1) {
        delete $1;
    }
}


/**
 * Type map for Rowset::next(GSRowSetType* type, Row* row, bool* hasNextRow,
 *                           QueryAnalysisEntry** queryAnalysis, AggregationResult** aggResult)
 */
%typemap(in, numinputs = 0) (GSRowSetType* type, griddb::Row* row, bool* hasNextRow,
    griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult)
    (GSRowSetType typeTmp, bool hasNextRowTmp,
            griddb::QueryAnalysisEntry* queryAnalysisTmp = NULL, griddb::AggregationResult* aggResultTmp = NULL) {
    $1 = &typeTmp;
    $2 = new griddb::Row();
    if ($2 == NULL) {
    	croak("Memory allocation error");
    }
    hasNextRowTmp = true;
    $3 = &hasNextRowTmp;
    $4 = &queryAnalysisTmp;
    $5 = &aggResultTmp;
}

%typemap(argout, fragment = "convertFieldToSV") (GSRowSetType* type, griddb::Row* row, bool* hasNextRow,
    griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult) 
{
	argvi = 0;						//Reset base output stack
	int count = $2->get_count();	//Array length of input

    griddb::AggregationResult *aggResult = NULL;
    griddb::QueryAnalysisEntry *queryAnalyResult = NULL;
    switch(*$1) {
        case (GS_ROW_SET_CONTAINER_ROWS):
            if (*$3 == false) {
            	$result = NULL;
            } else {
            	//Read each col from input then convert to field & increase output stack argvi
                for (argvi; argvi < count; argvi++) {
                	$result = sv_newmortal();	//Create the new SV no value
                	if($result == NULL){
                		croak("Memory allocation error");
                	}
                	convertFieldToSV($result, $2->get_field_ptr()[argvi], arg1->timestamp_output_with_float);
                }
            }
            break;
        case (GS_ROW_SET_AGGREGATION_RESULT):
            if (*$3 == false) {
                sv_setsv($result, NULL);
            } else {
                aggResult = *$5 ? (new griddb::AggregationResult((GSAggregationResult*)$5)) : 0;
                sv_setsv($result, SWIG_NewPointerObj(SWIG_as_voidptr(aggResult), SWIGTYPE_p_griddb__AggregationResult, SWIG_POINTER_OWN));
            }
            break;
        default:
            queryAnalyResult = *$4 ? (new griddb::QueryAnalysisEntry((GSQueryAnalysisEntry*)$4)) : 0;
            sv_setsv($result, SWIG_NewPointerObj(SWIG_as_voidptr(queryAnalyResult), SWIGTYPE_p_griddb__AggregationResult, SWIG_POINTER_OWN));
            break;
    }
    
    //return (void)$result;
}

%typemap(freearg) (GSRowSetType* type, griddb::Row* row, bool* hasNextRow,
        griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult) {
    if ($2) {
        delete $2;
    }
}

/**-------------------------------------PartitionController Class------------------------------------------------**/
/**
 * Type map for PartitionController::get_container_names(int32_t partition_index, int64_t start,
 *                                          const GSChar * const ** stringList, size_t *size, int64_t limit=-1)
 */
%typemap(in, numinputs = 0) (const GSChar * const ** stringList, size_t *size) (GSChar **nameList1, size_t size1) {
	$1 = &nameList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const GSChar * const ** stringList, size_t *size) (int i, size_t size) {
    GSChar** nameList1 = *$1;
    size_t size = *$2;

	//Read each name from name list then convert to output array & increase output stack argvi
    for (argvi = 0; argvi < size; argvi++) {
    	$result = sv_newmortal();							//Create the new SV no value
    	if($result == NULL){
    		croak("Memory allocation error");
    	}
    	sv_setpv($result, (const char*)nameList1[argvi]);	//Convert char* to SV
    }
}

%typemap(in, numinputs = 0) (const int **intList, size_t *size) (int *intList1, size_t size1) {
    $1 = &intList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const int **intList, size_t *size) (int i, size_t size) {
    int* intList = *$1;
    size_t size = *$2;

    //Read each value list then convert to output array & increase output stack argvi
    for (argvi = 0; argvi < size; argvi++) {
    	$result = sv_newmortal();				//Create the new SV no value
    	if($result == NULL){
    		croak("Memory allocation error");
    	}
    	sv_setiv($result, intList[argvi]);		//Convert int to SV
    }
}

%typemap(in, numinputs = 0) (const long **longList, size_t *size) (long *longList1, size_t size1) {
    $1 = &longList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const long **longList, size_t *size) (int i, size_t size) {
    long* longList = *$1;
    size_t size = *$2;

    //Read each value list then convert to output array & increase output stack argvi
    for (argvi = 0; argvi < size; argvi++) {
    	$result = sv_newmortal();				//Create the new SV no value
    	if($result == NULL){
    		croak("Memory allocation error");
    	}
    	sv_setnv($result, longList[argvi]);		//Convert float to SV
    }
}

%typemap(in, fragment = "convertSVToBlob") (const GSBlob *fieldValue) {
    $1 = (GSBlob*) malloc(sizeof(GSBlob));
    if ($1 == NULL) {
    	croak("Memory allocation error");
    }

    vbool = convertSVToBlob(value, &$1->size, (void**) &$1->data);
    if (!vbool) {
        free((void*) $1);
        return false;
    }
}

%typemap(freearg) (const GSBlob *fieldValue) {
    if ($1) {
        if ($1->data) {
            free ((void*) $1->data);
        }
        free((void *) $1);
    }
}

%typemap(in, numinputs = 0) (GSBlob *value) (GSBlob pValue) {
    $1 = &pValue;
}

%typemap(argout) (GSBlob *value) {
    GSBlob output = *$1;

	$result = sv_newmortal();				//Create the new SV no value
	if($result == NULL){
		croak("Memory allocation error");
	}
    sv_setpvn($result, (char*) output.data, output.size);		//Convert char* to SV
}

%typemap(out) GSColumnInfo {
	//Update name at base return stack
	argvi = 0;
	$result = sv_newmortal();					//Create the new SV no value
	if($result == NULL){
		croak("Memory allocation error");
	}
	sv_setpv($result, (const char*) $1.name);	//Convert char* to SV

	//Update type at next return stack
	argvi++;
	$result = sv_newmortal();					//Create the new SV no value
	if($result == NULL){
		croak("Memory allocation error");
	}
	sv_setiv($result, $1.type);					//Convert int to SV
}

/**-------------------------------------AggregationResult Class------------------------------------------------**/
/*
* typemap for AggregationResult::get()
*/
%typemap(in, numinputs = 0) (griddb::Field *agValue) (griddb::Field tmpAgValue){
    $1 = &tmpAgValue;
}
%typemap(argout, fragment = "convertFieldToSV") (griddb::Field *agValue) {
    convertFieldToSV($result, *$1, arg1->timestamp_output_with_float);
    argvi++;
}
