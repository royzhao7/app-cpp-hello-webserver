#ifndef APP_ARGS_CONSTR_H
#define APP_ARGS_CONSTR_H

#include <string>
#include <sys/stat.h>

#include <tclap/Constraint.h>

class os_dir_constr : public TCLAP::Constraint<std::string>
{
public:
    std::string description() const override
    {
        return "value must name an existing directory";
    }
    std::string shortID() const override
    {
        return "dir";
    }
    bool check(const std::string& value) const override
    {
        struct stat info;
        if (stat(value.c_str(), &info) != 0)
            return false;
        else
            return S_ISDIR(info.st_mode);
    }
};

#endif // APP_ARGS_CONSTR_H
