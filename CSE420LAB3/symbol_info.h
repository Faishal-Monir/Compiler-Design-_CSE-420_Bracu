#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    // Write necessary attributes to store the parameters of a function
    // Write necessary attributes to store the array size if the symbol is an array



    string category; // "Variable" / "Array" / "Function Definition"
    string data_type; // for variable/array
    
    bool is_array = false;
    int array_size = -1;

    bool is_function = false;
    string return_type;
    vector<pair<string, string>> parameters; // (type, name)

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
    }
    symbol_info(string name, string type, string data_type)
    {
        this->name = name;
        this->type = type;
        this->data_type = data_type;
        this->category = "Variable";
    }
    symbol_info(string name, string type, string data_type, int array_size)
    {
        this->name = name;
        this->type = type;
        this->data_type = data_type;
        this->category = "Array";
        this->is_array = true;
        this->array_size = array_size;
    }
    string getname()
    {
        return name;
    }
    string gettype()
    {
        return type;
    }



    // Compatibility helpers (existing parser uses getname/gettype)
 
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes



    void set_category(const string &category)
    {
        this->category = category;
        this->is_function = (category == "Function Definition");
        this->is_array = (category == "Array");
    }
    string get_category()
    {
        return category;
    }



    void set_data_type(const string &data_type)
    {
        this->data_type = data_type;
    }
    string get_data_type()
    {
        return data_type;
    }



    void set_array_size(int size)
    {
        is_array = true;
        array_size = size;
        category = "Array";
    }
    bool get_is_array()
    {
        return is_array;
    }
    int get_array_size()
    {
        return array_size;
    }



    void set_as_function(const string &return_type, const vector<pair<string, string>> &params)
    {
        is_function = true;
        category = "Function Definition";
        this->return_type = return_type;
        parameters = params;
    }
    bool get_is_function()
    {
        return is_function;
    }
    string get_return_type()
    {
        return return_type;
    }
    vector<pair<string, string>> get_parameters()
    {
        return parameters;
    }



    string format_parameter_details()
    {
        string details;
        for (size_t i = 0; i < parameters.size(); i++)
        {
            if (i > 0)
                details += ", ";
            details += parameters[i].first;
            if (!parameters[i].second.empty())
                details += " " + parameters[i].second;
        }
        return details;
    }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};
