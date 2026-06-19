#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        // write your hash function here
        int hash_value = 0;
        for (char ch : name)
        {
            hash_value += (int)ch;
        }
        hash_value %= bucket_count;
        if (hash_value < 0)
            hash_value += bucket_count;
        return hash_value;
    }

    public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

};




scope_table::scope_table()
{
    bucket_count = 0;
    unique_id = 0;
    parent_scope = NULL;
}



scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    table.clear();
    table.resize(bucket_count);
}



scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}



int scope_table::get_unique_id()
{
    return unique_id;
}



symbol_info *scope_table::lookup_in_scope(symbol_info *symbol)
{
    if (symbol == NULL)
        return NULL;

    int index = hash_function(symbol->getname());
    for (symbol_info *current : table[index])
    {
        if (current != NULL && current->getname() == symbol->getname())
            return current;
    }
    return NULL;
}



bool scope_table::insert_in_scope(symbol_info *symbol)
{
    if (symbol == NULL)
        return false;

    if (lookup_in_scope(symbol) != NULL)
        return false;

    int index = hash_function(symbol->getname());
    table[index].push_back(symbol);
    return true;
}



bool scope_table::delete_from_scope(symbol_info *symbol)
{
    if (symbol == NULL)
        return false;

    int index = hash_function(symbol->getname());
    auto &bucket = table[index];
    for (auto it = bucket.begin(); it != bucket.end(); ++it)
    {
        if (*it != NULL && (*it)->getname() == symbol->getname())
        {
            delete *it;
            bucket.erase(it);
            return true;
        }
    }
    return false;
}



static void print_symbol_entry(ofstream &outlog, symbol_info *sym)
{
    outlog << "< " << sym->getname() << " : " << sym->gettype() << " >" << endl;

    if (sym->get_is_function())
    {
        outlog << "Function Definition" << endl;
        outlog << "Return Type: " << sym->get_return_type() << endl;
        outlog << "Number of Parameters: " << sym->get_parameters().size() << endl;
        outlog << "Parameter Details: " << sym->format_parameter_details() << endl;
        return;
    }

    if (sym->get_is_array())
    {
        outlog << "Array" << endl;
        outlog << "Type: " << sym->get_data_type() << endl;
        outlog << "Size: " << sym->get_array_size() << endl
               << endl;
        return;
    }

    outlog << "Variable" << endl;
    outlog << "Type: " << sym->get_data_type() << endl
           << endl;
}



void scope_table::print_scope_table(ofstream &outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;

    for (int i = 0; i < bucket_count; i++)
    {
        if (table[i].empty())
            continue;

        outlog << i << " --> " << endl;
        for (symbol_info *sym : table[i])
        {
            if (sym == NULL)
                continue;
            print_symbol_entry(outlog, sym);
        }
    }

    outlog << endl;
}



scope_table::~scope_table()
{
    for (auto &bucket : table)
    {
        for (symbol_info *sym : bucket)
        {
            delete sym;
        }
        bucket.clear();
    }
    table.clear();
}
