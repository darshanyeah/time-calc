#!/bin/bash

# Time Calculator Script
# Asks for current completed time, calculates remaining time, and shows completion time

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to convert HH:MM to minutes
time_to_minutes() {
    local time=$1
    IFS=':' read -r hours minutes <<< "$time"
    # Remove leading zeros to avoid octal interpretation
    hours=$((10#$hours))
    minutes=$((10#$minutes))
    echo $((hours * 60 + minutes))
}

# Function to convert minutes to HH:MM format
minutes_to_time() {
    local total_minutes=$1
    local hours=$((total_minutes / 60))
    local minutes=$((total_minutes % 60))
    printf "%02d:%02d" $hours $minutes
}

# Function to validate time format
validate_time() {
    local time=$1
    if [[ $time =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
        IFS=':' read -r hours minutes <<< "$time"
        if [ "$hours" -ge 0 ] && [ "$hours" -le 23 ] && [ "$minutes" -ge 0 ] && [ "$minutes" -le 59 ]; then
            return 0
        fi
    fi
    return 1
}

# Function to add minutes to current time and get completion time
calculate_completion_time() {
    local remaining_minutes=$1
    local completion_time=$(date -d "+${remaining_minutes} minutes" +"%I:%M %p")
    local completion_date=$(date -d "+${remaining_minutes} minutes" +"%Y-%m-%d")
    local current_date=$(date +"%Y-%m-%d")
    
    if [ "$completion_date" = "$current_date" ]; then
        echo "Today at $completion_time"
    else
        echo "$(date -d "+${remaining_minutes} minutes" +"%a, %b %d at %I:%M %p")"
    fi
}

# Main script
clear
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}    Time Calculator Script${NC}"
echo -e "${BLUE}================================${NC}\n"

# Get target working hours with default
echo -e "${YELLOW}Default target working hours: 8:00${NC}"
echo -e "${YELLOW}Do you want to change the target hours? (y/n):${NC}"
read -p "Change target? " change_target

if [[ $change_target =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Enter your target working hours for today (e.g., 9:00):${NC}"
    read -p "Target hours: " target_time
    
    # Validate target time
    if ! validate_time "$target_time"; then
        echo -e "${RED}Invalid time format! Please use HH:MM format.${NC}"
        exit 1
    fi
else
    target_time="8:00"
    echo -e "${GREEN}Using default target: 8:00${NC}"
fi

# Get current completed time
echo -e "\n${YELLOW}Enter the time you've already completed today (e.g., 3:30):${NC}"
read -p "Completed time: " completed_time

# Validate completed time
if ! validate_time "$completed_time"; then
    echo -e "${RED}Invalid time format! Please use HH:MM format.${NC}"
    exit 1
fi

# Convert times to minutes for calculation
target_minutes=$(time_to_minutes "$target_time")
completed_minutes=$(time_to_minutes "$completed_time")

# Calculate remaining time
remaining_minutes=$((target_minutes - completed_minutes))

# Get current system time
current_time=$(date +"%I:%M %p")
current_date=$(date +"%A, %B %d, %Y")

echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}         RESULTS${NC}"
echo -e "${BLUE}================================${NC}"

echo -e "${YELLOW}Current Date & Time:${NC} $current_date at $current_time"
echo -e "${YELLOW}Target Working Hours:${NC} $target_time"
echo -e "${YELLOW}Completed Time:${NC} $completed_time"

if [ $remaining_minutes -gt 0 ]; then
    remaining_time_formatted=$(minutes_to_time $remaining_minutes)
    completion_time=$(calculate_completion_time $remaining_minutes)
    
    echo -e "${RED}Remaining Time:${NC} $remaining_time_formatted"
    echo -e "${GREEN}Estimated Completion:${NC} $completion_time"
    
    # Calculate percentage completed
    percentage=$((completed_minutes * 100 / target_minutes))
    echo -e "${YELLOW}Progress:${NC} $percentage% completed"
    
    # Show progress bar (10 points, each covering 10%)
    filled=$((percentage / 10))
    empty=$((10 - filled))
    printf "${YELLOW}Progress Bar:${NC} ["
    for ((i=0; i<filled; i++)); do printf "${GREEN}* "; done
    for ((i=0; i<empty; i++)); do printf "${RED}- ${NC}"; done
    # Set color based on percentage
    if [ $percentage -lt 40 ]; then
        printf "] ${RED}%d%%${NC}\n" $percentage
    elif [ $percentage -lt 70 ]; then
        printf "] ${YELLOW}%d%%${NC}\n" $percentage
    elif [ $percentage -lt 98 ]; then
        printf "] ${BLUE}%d%%${NC}\n" $percentage
    else
        printf "] ${GREEN}%d%%${NC}\n" $percentage
    fi
    
elif [ $remaining_minutes -eq 0 ]; then
    echo -e "${GREEN}🎉 Congratulations! You've completed your target hours!${NC}"
else
    overtime_minutes=$((-remaining_minutes))
    overtime_formatted=$(minutes_to_time $overtime_minutes)
    echo -e "${GREEN}🎉 Target completed! You've worked overtime: $overtime_formatted${NC}"
    
    percentage=$((completed_minutes * 100 / target_minutes))
    echo -e "${YELLOW}Progress:${NC} $percentage% completed"
fi

echo -e "\n${BLUE}================================${NC}"

echo -e "\n${GREEN}Thank you for using Time Calculator!${NC}"