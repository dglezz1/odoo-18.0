#!/usr/bin/env python3
"""
Script to wait for PostgreSQL to be available
Used in Docker containers to ensure DB is ready before starting Odoo
"""

import argparse
import psycopg2
import sys
import time
from psycopg2 import OperationalError


def wait_for_db(host, port, user, password, timeout=60, interval=1):
    """Wait for PostgreSQL database to be available"""
    print(f"Waiting for PostgreSQL at {host}:{port}...")
    
    start_time = time.time()
    
    while True:
        try:
            # Attempt to connect to PostgreSQL
            conn = psycopg2.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database='postgres'  # Connect to default postgres database
            )
            conn.close()
            print("✅ PostgreSQL is available!")
            return True
            
        except OperationalError as e:
            elapsed_time = time.time() - start_time
            
            if elapsed_time >= timeout:
                print(f"❌ Timeout: PostgreSQL not available after {timeout} seconds")
                print(f"Last error: {e}")
                return False
            
            print(f"⏳ PostgreSQL not ready yet... ({elapsed_time:.1f}s elapsed)")
            time.sleep(interval)
            
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Wait for PostgreSQL to be available'
    )
    parser.add_argument(
        '--host', 
        default='localhost',
        help='PostgreSQL host (default: localhost)'
    )
    parser.add_argument(
        '--port',
        type=int,
        default=5432,
        help='PostgreSQL port (default: 5432)'
    )
    parser.add_argument(
        '--user',
        default='postgres',
        help='PostgreSQL user (default: postgres)'
    )
    parser.add_argument(
        '--password',
        default='',
        help='PostgreSQL password'
    )
    parser.add_argument(
        '--timeout',
        type=int,
        default=60,
        help='Timeout in seconds (default: 60)'
    )
    parser.add_argument(
        '--interval',
        type=float,
        default=1,
        help='Check interval in seconds (default: 1)'
    )
    
    args = parser.parse_args()
    
    success = wait_for_db(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        timeout=args.timeout,
        interval=args.interval
    )
    
    if success:
        print("PostgreSQL connection successful!")
        sys.exit(0)
    else:
        print("Failed to connect to PostgreSQL")
        sys.exit(1)


if __name__ == '__main__':
    main()
