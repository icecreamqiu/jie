
###set source code root path###
ANDROID_BUILD_TOP=`pwd`;


##Get Defults Revision##
function get_master_branch() {
    cd $ANDROID_BUILD_TOP/.repo;
    if [[ $? != 0 ]]; then
        echo -e "\n\033[41;37mPlease check Whether is you in Android Root Path??\033[0m\n";
        exit 1;
    fi
    local revision=`cat "$ANDROID_BUILD_TOP/.repo/manifest.xml" |grep "default revision"`;
    revision=${revision//\"/ };
    local branch_name=`echo $revision | awk '{print $3}'`;
    cd $ANDROID_BUILD_TOP;
    echo $branch_name;
}

##check branch whether is exits##
function verify_branch() {
    cd $ANDROID_BUILD_TOP/frameworks/base;
    local verify_branch_name=`git branch -r | grep -wo $1`;
    cd $ANDROID_BUILD_TOP;

    if [[ -z "$verify_branch_name" ]]; then
        echo -e "\033[41;37m#####################################################################\033[0m";
        echo -e "your project has no branch: [\033[44;37m$1\033[0m], please add branch";
        echo -e "\033[41;37m#####################################################################\033[0m\n";
        return 1;
    fi

    return 0;
}

##check tag whether is exits##
function verify_tag() {
    cd $ANDROID_BUILD_TOP/frameworks/base;
    local verify_tag_name=`git tag | grep -xo ${1}`;
    cd $ANDROID_BUILD_TOP;

    if [[ -z "$verify_tag_name" ]]; then
        echo -e "\n   no exist tag : \033[41;37m$1\033[0m\n";
        return 1;
    fi

    return 0;
}

##merge other branch to HEAD branch##
function merge_code()
{
    echo -e "\nStart merge code, please wait...";
    cd $ANDROID_BUILD_TOP;
    local rel_branch_name=$1;
    local merge_target_name=$2;
    local error_num=0;
    local project_list=$(grep -Ev "^$|#|%" "$ANDROID_BUILD_TOP/.repo/project.list");
    for project in $project_list
    do
        cd $ANDROID_BUILD_TOP/$project;
        ##befer merge, reset current directory##
        git reset --hard HEAD >/dev/null 2>&1;
        git merge $merge_target_name --no-edit >/dev/null 2>&1;
        merge_err=$?;
        if [[ $merge_err != 0 ]]; then
            error_proejct_list[$error_num]=$project;
            let error_num++;
            DIFF_ERROR=true;
        fi
    done

    cd $ANDROID_BUILD_TOP;
    if [[ $DIFF_ERROR == true ]]; then
        echo -e "\033[41;37m###################################################################\033[0m";
        echo -e "\033[41;37m----------------------------no merge-------------------------------\033[0m";
        echo -e "\033[41;37m--------------------Please to resolved conflict--------------------\033[0m";
        echo -e "Please enter path,usage:\033[44;37mgit diff HEAD $merge_target_name\033[0m to check diff\n";
        echo -e "you can use \033[44;37m[git log] or [git log --graph]\033[0m to check code's sequence";
        echo -e "Log record comparison between \033[41;37m$merge_target_name and $rel_branch_name\033[0m\n";
        echo -e "you will use other cmd: [\033[41;37mgit diff; git status;git checkout branchName;git branch;
                   git status -s; git add . --all; git commit -n\033[0m]\n";
        echo -e "\033[41;37m-------------those have $error_num conflict path as follows--------\033[0m";
        echo -e "\033[41;37m###################################################################\033[0m";
        for ((i=0; i<error_num; i++))
        do
            echo -e "\033[44;37m${error_proejct_list[$i]}\033[0m"
        done
        echo -e "\033[41;37m###################################################################\033[0m";
        echo -e "\n\033[44;37mAfter resolved conflict, you can extcute [diff] option\033[0m";
        echo -e "\033[41;37m###################################################################\033[0m";
        return 1;
    else
        echo -e "\n------------merge code done!---------------\n";
        return 0;
    fi
}

##check relbranch and mstarbranch's code whether is same##
function diff_code()
{
    echo -e "\nStart diff code, please wait...";
    cd $ANDROID_BUILD_TOP;
    local diff_target_name=$1;
    local error_num=0;
    local project_list=$(grep -Ev "^$|#|%" "$ANDROID_BUILD_TOP/.repo/project.list");
    for project in $project_list
    do
        cd $ANDROID_BUILD_TOP/$project;
        git diff --exit-code $diff_target_name >/dev/null 2>&1;
        diff_err=$?;
        if [[ $diff_err != 0 ]]; then
            error_proejct_list[$error_num]=$project;
            let error_num++;
            DIFF_ERROR=true;
        fi
    done

    cd $ANDROID_BUILD_TOP;
    if [[ $DIFF_ERROR == true ]]; then
        echo -e "\033[41;37m###################################################################\033[0m";
        echo -e "\033[41;37m----------------------------diff code------------------------------\033[0m";
        echo -e "\033[41;37m---Please to check conflict, they are you want to fix????----------\033[0m";
        echo -e "\nPlease enter path,usage:\033[44;37mgit diff HEAD $diff_target_name\033[0m to check diff";
        echo -e "you can use \033[44;37m[git log] or [git log --graph]\033[0m to check code's sequence";
        echo -e "\033[41;37m-------------Log record comparison between branch------------------\033[0m\n";
        echo -e "\033[41;37m--------------those have $error_num diff path as follows------------\033[0m";
        echo -e "\033[41;37m###################################################################\033[0m";
        for ((i=0; i<error_num; i++))
        do
            echo -e "\033[44;37m${error_proejct_list[$i]}\033[0m"
        done
        echo -e "\033[41;37m###################################################################\033[0m";
        return 1;
    else
        echo -e "\n------------diff code done, it is same!---------------\n";
        return 0;
    fi
}

##push tag to git server##
function push_tag()
{
    local tag_name=$1;
    echo -e "\nStart push tag, please wait...";
    local project_list=$(grep -Ev "^$|#|%" "$ANDROID_BUILD_TOP/.repo/project.list");
    for project in $project_list
    do
        cd $ANDROID_BUILD_TOP/$project;
        git push aosp $tag_name >/dev/null 2>&1;
        PUSH_TAG_ERROR=$?;
        if [[ $PUSH_TAG_ERROR != 0 ]]; then
            git push aosp $tag_name /dev/null 2>&1;
            if [[ $? != 0 ]]; then
                ERROR_TAG=true;
                tag_error_path=$project;
                break;
            fi
        fi
    done

    if [[ $ERROR_TAG == true ]]; then
        echo -e "\033[41;37m ################################################################# \033[0m";
        git push aosp $tag_name;
        echo -e "\n can not push tag\033[44;37m $tag_name\033[0m, path is :
                \033[41;37m$tag_error_path\033[0m";
        echo -e "\033[41;37m ############################################################### \033[0m\n";
        echo -e "you can use \033[44;37m[git log] or [git log --graph]\033[0m to check code's sequence";
        echo -e "\033[41;37m-----------Log record comparison between branch------------------\033[0m\n";
        echo -e "you will use other cmd: [ git branch; git diff; git status;git checkout branchName ]\n";
        echo -e "\033[41;37m ############################################################### \033[0m";
        echo -e "\033[41;37m ## if you resolved this problem, reexecute the push operation## \033[0m";
        echo -e "\033[41;37m ############################################################### \033[0m\n";
        cd $ANDROID_BUILD_TOP;
        return 1;
    else
        cd $ANDROID_BUILD_TOP;
        echo -e "\n----------tag push done----------\n";
        return 0;
    fi
}

##checkout to relbranch and merge mstarbranch to relbranch##
function checkout_branch()
{
    if [[ -z "$1" ]]; then
        echo -e "\n--------------------\033[41;37mbranch is null!!!\033[0m---------------------\n";
        return 1;
    fi
    local branch_name=$1;
    echo -e "\nStart checkout to $branch_name, please wait...";
    local error_check=0;
    local project_list=$(grep -Ev "^$|#|%" "$ANDROID_BUILD_TOP/.repo/project.list");
    for project in $project_list
    do
        cd $ANDROID_BUILD_TOP/$project;
        git checkout -f -B tmp_branch >/dev/null 2>&1;
        git branch -D `git branch | grep -v \* | xargs` >/dev/null 2>&1;
        git checkout -f --track m/$branch_name >/dev/null 2>&1;
        CHECKOUT_RELNUM=$?;
        if [[ $CHECKOUT_RELNUM != 0 ]]; then
            git checkout -f --track m/$branch_name >/dev/null 2>&1;
            CHECKOUT_RELNUM=$?;

            if [[ $CHECKOUT_RELNUM != 0 ]]; then
                git checkout -f --track aosp/$branch_name >/dev/null 2>&1;
                CHECKOUT_RELNUM=$?;

                if [[ $CHECKOUT_RELNUM != 0 ]]; then
                    git checkout -f --track origin/$branch_name >/dev/null 2>&1;
                    CHECKOUT_RELNUM=$?;
                fi
            fi

            if [[ $CHECKOUT_RELNUM != 0 ]]; then
                CHECKOUT_ARRAY[$error_check]=$project;
                let error_check++;
                ERROR_REL=true;
            fi
        fi
        git branch -D tmp_branch >/dev/null 2>&1;
    done

    cd $ANDROID_BUILD_TOP;
    if [[ $ERROR_REL == true ]]; then
        echo -e "\033[41;37m#########################################################################################\033[0m";
        echo -e "\033[41;37myour project has not branch in some path, please check these path is you want to checkout\033[0m";
        echo -e "you can use these cmd to check:[\033[44;37mgit branch -r\033[0m] to check whether $branch_name is exist?";
        echo -e "can use these cmd to check:[\033[44;37mgit checkout -f --track m/$branch_name\033[0m]
                 to check error message";
        echo -e "\033[41;37m#########################################################################################\033[0m";
        for ((i=0; i<error_check; i++))
        do
            echo "${CHECKOUT_ARRAY[$i]}"
        done
        echo -e "\033[41;37m#########################################################################################\033[0m";
        echo -e "\033[41;37mThose have $error_check git projects below don't have $branch_name\033[0m";
        echo -e "\033[41;37mPlease contact administrator to add.\033[0m\n";
        echo -e "\033[41;37m#########################################################################################\033[0m";
        echo -e "\n\033[44;37mif you resolved this problem, you can use last cmd to sync code again!\033[0m";
        echo -e "\033[41;37m#########################################################################################\033[0m";
        return 1;
    else
        echo -e "\n ------- checkout branch done! --------\n";
        return 0;
    fi
}

##push relbranch's code to git server##
function push_branch()
{
    local branch_name=$1;
    echo -e "\nCurrent path is : $ANDROID_BUILD_TOP";
    echo -e "\nstart push $branch_name, please wait..."
    local project_list=$(grep -Ev "^$|#|%" "$ANDROID_BUILD_TOP/.repo/project.list");
    for project in $project_list
    do
        cd $ANDROID_BUILD_TOP/$project;
        git push aosp HEAD:refs/heads/$branch_name >/dev/null 2>&1;
        ERROR_PSUHNUM=$?;
        if [[ $ERROR_PSUHNUM == 1 ]]; then
            git push aosp HEAD:refs/heads/$branch_name >/dev/null 2>&1;
            ERROR_PSUHNUM=$?;
            if [[ $ERROR_PSUHNUM == 1 ]]; then
                echo -e "\033[41;37m ###########################################################################################\033[0m";
                git push aosp HEAD:refs/heads/$branch_name;
                echo -e "\n\033[41;37m push error path is--->>> $ANDROID_BUILD_TOP/$project\033[0m";
                break;
            fi
        fi
    done

    cd $ANDROID_BUILD_TOP;
    if [[ $ERROR_PSUHNUM == 1 ]]; then
        echo -e "\ncan use these cmd to check:[\033[44;37mgit branch -r\033[0m] to check whether $branch_name is exist?";
        echo -e "can use these cmd to check: \033[44;37m[ git log ] or [ git diff ]\033[0m to check you whether modif code\n";
        echo -e "\033[41;37m ###########################################################################################\033[0m";
        echo -e "\033[41;37m ########### if you resolved this problem, reexecute the push operation ####################\033[0m";
        echo -e "\033[41;37m ###########################################################################################\033[0m";
        return 1;
    else
        echo -e "\n----------push code done----------\n";
        return 0;
    fi
}

## clear source code modif
function clean_source_code()
{
    echo -e "\nStart to rest code base, please wait...";
    repo forall -c 'git clean -df;git reset HEAD --hard;git rebase --abort;' >/dev/null 2>&1;
    repo forall -c "git checkout -f -B tmp_branch" >/dev/null 2>&1;
    repo forall -c "git reset --hard HEAD" >/dev/null 2>&1;
    repo forall -c 'git branch -D `git branch | grep -v \* | xargs`' >/dev/null 2>&1;
    repo abandon tmp_branch >/dev/null 2>&1;
    echo -e "\n----------clear done-----------";
}

##sync tip code to your local project##
function reset_sync_code()
{
    echo "";
    local create_branch=$1;
    read -p "---------- Reset Code Base, to erase all modify ---------- Y/N :" tmp;
    if [[ $tmp == "y" ]] || [[ $tmp == "Y" ]]; then
        clean_source_code;

        if [[ -z "$create_branch" ]]; then
            echo -e "\nStart to sync code, please wait...";
            repo sync -f -d -j32;
            local repo_error=$?;
            local master_branch=$(get_master_branch);
            if [[  $repo_error == 1 ]]; then
                echo -e "\033[41;37m########################################################################\033[0m";
                echo -e "\033[41;37m########################## repo sync error #############################\033[0m";
                echo -e "\033[41;37m############## Please check git server whether is work normally#########\033[0m";
                echo -e "\033[41;37m######Please after sync done , create $master_branch manually########\033[0m";
                echo -e "usage: \033[44;37mrepo forall -c \"git checkout -f --track m/$master_branch\"\033[0m";
                echo -e "\033[41;37m########################################################################\033[0m";
                return 1;
            fi

            checkout_branch $master_branch;
            if [[ $? == 1 ]]; then
                return 1;
            fi
        fi
    else
        echo -e "\n\033[41;37mexit scrtips!!!\033[0m"
        return 1;
    fi
}

##make a tag##
function make_tag()
{
    cd $ANDROID_BUILD_TOP;
    local tag_name=$1;
    local tag_msg=$2;
    echo -e "\nStart make a tag $tag_name, message is: $tag_msg, please wait...";
    repo forall -c "git tag -a $tag_name -m '$tag_msg'";
    if [[ $? != 0 ]]; then
        echo -e "\n\033[41;37mMake tag failed!!!\033[0m\n";
        return 1;
    fi

    return 0;

}

##judge whether push relbranch's code to git server and push a tag to git server##
function push_to_server()
{
    push_branch $1;
    if [[ $? == 1 ]]; then
        return 1;
    fi

    push_tag $2;
    if [[ $? == 1 ]]; then
        return 1;
    fi
}

##checkout to relbranch, merge masterbranch code and diff code##
function checkout_merge_code()
{
    local rel_branch_name=$1;
    local merge_target=$2;
    checkout_branch $rel_branch_name;
    if [[ $? == 1 ]]; then
        return 1;
    fi

    merge_code $rel_branch_name $merge_target;
    if [[ $? == 1 ]]; then
        return 1;
    fi

}

#############################################################################
################################## main #####################################
#############################################################################

##check master line and top path whether is exist##
get_master_branch;
echo -e "\nCurrent project master branch is : \033[044;37m$(get_master_branch)\033[0m\n";

##get user input message##
if [[ -z ${1}  ]] ||
   ( [[ ${1} != "sync" ]] &&
     [[ ${1} != "abandon" ]] &&
     [[ ${1} != "branch" ]] &&
     [[ ${1} != "syncmerge" ]] &&
     [[ ${1} != "diff" ]] &&
     [[ ${1} != "push" ]] ); then
        echo -e "\n\033[41;37musage: ${0} sync\033[0m";
        echo -e "\033[41;37musage: ${0} abandon\033[0m";
        echo -e "\033[41;37musage: ${0} branch\033[0m";
        echo -e "\033[41;37musage: ${0} syncmerge\033[0m";
        echo -e "\033[41;37musage: ${0} diff\033[0m";
        echo -e "\033[41;37musage: ${0} push\033[0m\n";
fi

##judge user input which event##
if [[ $1 == "sync" ]]; then

    #if [ $# = 1 ]; then
    #    echo -e "\n\033[41;37m---------------------------sync code--------------------------\033[0m";
    #    echo -e "\033[44;37musage: ${0} sync\033[0m";
    #    echo -e "\033[44;37mexample: ${0} sync\033[0m";
    #    echo -e "\033[41;37m------------------------------sync code--------------------------\033[0m\n";
    #    exit 0;
    #fi
    reset_sync_code $2;
    if [[ $? != 0 ]]; then
        exit 1;
    fi

elif [[ $1 == "abandon" ]]; then

    clean_source_code;

elif [[ $1 == "branch" ]]; then

    if [[ -z "$2" ]]; then
        master_branch=$(get_master_branch);
        if ! [[ -z "$master_branch" ]]; then
            checkout_branch $master_branch;
            if [[ $? == 1 ]]; then
                exit 1;
            fi
        fi
    else   
        checkout_branch $2;
        if [[ $? == 1 ]]; then
            exit 1;
        fi
    fi

    #repo branches

elif [[ $1 == "syncmerge" ]]; then
    rel_branch=$2;
    merge_tag=$3;
    INPUT_NUM=$#;
    if [ $INPUT_NUM != 2 ] && [ $INPUT_NUM != 3 ]; then
        echo -e "\n\033[41;37m-----------------------------merge mastar to rel line----------------------\033[0m";
        echo -e "\033[44;37musage: ${0} syncmerge [rel_branch]\033[0m";
        echo -e "\033[44;37mexample: ${0} syncmerge lollipop-muji-rel\033[0m";
        echo -e "\n\033[41;37m-----------------------------merge tag to rel line----------------------\033[0m";
        echo -e "\033[44;37musage: ${0} syncmerge [rel_branch] [LOLLIPOP_MUJI_2.0.9]\033[0m";
        echo -e "\033[44;37mexample: ${0} syncmerge lollipop-mujimi-rel LOLLIPOP_MUJI_2.0.9\033[0m";
        echo -e "\033[41;37m----------------------------------merge--------------------------------------\033[0m\n";
        exit 0;
    fi

    verify_branch $rel_branch;
    if [[ $? != 0 ]]; then
        echo -e "\033[41;37m########################################################################################\033[0m";
        echo -e "\nrelbranch : \033[44;37m$rel_branch is not exist\033[0m in your project, please check git server had add this branch???\n";
        read -p "you want to sync code continue?? Y/N :" branchtmp;
        if ! ([[ $branchtmp == "Y" ]] || [[ $branchtmp == "y" ]]); then
            echo -e "\n\033[41;37mexit scrtips!!!\033[0m";
            exit 1;
        fi
    fi

    if [ $INPUT_NUM == 2 ]; then
        merge_target=$(get_master_branch);

    elif [ $INPUT_NUM == 3 ]; then
        merge_target=$merge_tag;
        verify_tag $merge_target;
        if [[ $? != 0 ]]; then
            echo -e "\ntag: \033[41;37m$merge_target is not exist\033[0m in your project, please check this had push git server???\n";
            read -p "you want to sync code continue?? Y/N :" branchtmp;
            if ! ([[ $branchtmp == "Y" ]] || [[ $branchtmp == "y" ]]); then
                echo -e "\n\033[41;37mexit scrtips!!!\033[0m";
                exit 1;
            fi

        fi
    fi

    reset_sync_code;
    if [[ $? != 0 ]]; then
        exit 1;
    fi

    verify_branch $rel_branch;
    if [[ $? != 0 ]]; then
        exit 1;
    fi

    if [ $INPUT_NUM == 3 ]; then
        verify_tag $merge_tag;
        if [[ $? != 0 ]]; then
            echo -e "\033[41;37m#####################################################################\033[0m";
            echo -e "your project has no tag: [\033[44;37m$merge_tag\033[0m], please check this merge_tag,
                                                   whether it had push git server???";
            echo -e "\033[41;37m#####################################################################\033[0m";
            exit 1;
        fi
    fi

    echo -e "\n-------merge branch $merge_target-------\n";
    checkout_merge_code $rel_branch $merge_target;
    if [[ $? != 0 ]]; then
        echo -e "\n\033[41;37mcheckout_merge_code failed!!!\033[0m\n"
        exit 1;
    fi
## If you currently have fought several tag, a1, a2, a3, so your rel line now
## the latest code is the same as with a3. When you go to merge tag a1 or a2 to rel line,
## merge was successful, but when you diff code tag a1, a2 and contrast rel line is not the same,
## so adding a diff_code operation to prevent merge the wrong tag
    if [ $INPUT_NUM == 3 ]; then
        diff_code $merge_target;
        if [[ $? != 0 ]]; then
            echo -e "\n\033[44;37mplease check whether you merge error tag, this tag [$merge_target] is not last tag???.\033[0m\n"
            exit 1;
        fi
    fi

    echo -e "\nsyncmerge is soccess, you can change BUILD_NUM? or make build image?"
elif [[ $1 == "diff" ]]; then
    diff_target=$2;
    if [ $# != 2 ]; then
        echo -e "\n\033[41;37m-----------------------diff code-----------------------------\033[0m";
        echo -e "\033[44;37musage: ${0} diff [diff_target]\033[0m";
        echo -e "\033[44;37mexample: ${0} diff lollipop-mstar-master\033[0m";
        echo -e "\033[41;37m--------------------------diff code--------------------------\033[0m\n";
        exit 0;
    fi

    verify_tag $diff_target;
    if [[ $? != 0 ]]; then
        verify_branch $diff_target;
        if [[ $? != 0 ]]; then
            exit 1;
        fi
    fi

    diff_code $diff_target;
    if [[ $? != 0 ]]; then
        exit 1;
    fi
    echo -e "\n\033[44;37mdiff code is same, you can make build image now.\033[0m\n"

elif [[ $1 == "push" ]]; then
    rel_branch_name=$2;
    tag_name=$3;
    tag_msg=$4;
    if [ $# != 4 ]; then
        echo -e "\n\033[41;37m--------------------------------------make tag-----------------------------------\033[0m";
        echo -e "\033[44;37musage: ${0} push [rel_branch_name] [tag_name] [tag_msg]\033[0m";
        echo -e "\033[44;37mexample: ${0} push lollipop-muji-rel LOLLIPOP_MUJI_2.0.9 \"Lollipop Muji Release 2.0.9\"\033[0m";
        echo -e "\033[41;37m-----------------------------------------make tag------------------------------------\033[0m\n";
        exit 0;
    fi

    verify_branch $rel_branch_name;
    if [[ $? != 0 ]]; then
        exit 1;
    fi

    verify_tag $tag_name;
    if [[ $? != 0 ]]; then
        make_tag $tag_name "$tag_msg";
        if [[ $? != 0 ]]; then
            exit 1;
        fi
    else
        echo -e "\033[44;37mtag :$tag_name had exist, please whether check this tag is right!!!\033[0m\n";
        read -p "you project has exist this tag, you want to push code again?? Y/N :" tmp;
        if ! ([[ $tmp == "Y" ]] || [[ $tmp == "y" ]]); then
            echo -e "\n\033[41;37mexit scrtips!!!\033[0m"
            exit 1;
        fi
    fi

    push_to_server $rel_branch_name $tag_name;
    if [[ $? != 0 ]]; then
        echo -e "\n\033[41;37mpush_to_server failed!!!\033[0m\n"
        echo -e "\033[41;37m if you resolved this problem, reexecute the push operation\033[0m\n";
        exit 1;
    fi
fi
