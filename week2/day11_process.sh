#!/bin/bash

# ===============================
# Day 11: Process Manager Script
# ===============================

while true; do
    echo "=============================="
    echo "     PROCESS MANAGER MENU     "
    echo "=============================="
    echo "1. List all processes"
    echo "2. Find process by name"
    echo "3. Kill process by PID"
    echo "4. Show top 5 CPU-consuming processes"
    echo "5. Exit"
    echo "=============================="
    read -p "Choose an option (1-5): " OPTION

    case $OPTION in

        1)
            echo -e "\n📌 Listing all running processes..."
            ps aux | less
            ;;

        2)
            read -p "Enter process name to search: " NAME
            echo -e "\n🔍 Searching for process: $NAME"
            ps aux | grep -i "$NAME" | grep -v grep
            ;;

        3)
            read -p "Enter PID to kill: " PID

            # Validate PID is a number
            if ! [[ $PID =~ ^[0-9]+$ ]]; then
                echo "❌ Invalid PID. Please enter a number."
            else
                echo -e "\n⚠️  WARNING: You are about to kill PID $PID"
                read -p "Are you sure? (y/n): " CONFIRM

                if [[ $CONFIRM == "y" ]]; then
                    kill $PID 2>/dev/null

                    if [[ $? -eq 0 ]]; then
                        echo "✅ Process $PID terminated successfully."
                    else
                        echo "❌ Failed to kill process. Check if PID exists or requires sudo."
                    fi
                else
                    echo "❗ Kill operation canceled."
                fi
            fi
            ;;

        4)
            echo -e "\n🔥 Top 5 CPU-consuming processes:"
            ps aux --sort=-%cpu | head -n 6
            ;;

        5)
            echo "👋 Exiting Process Manager. Goodbye!"
            exit 0
            ;;

        *)
            echo "❌ Invalid option. Please choose 1–5."
            ;;

    esac

    echo -e "\nPress Enter to return to menu..."
    read
done
