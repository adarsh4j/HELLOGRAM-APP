import { createPool, Pool } from 'mysql2/promise';

export const connect = async (): Promise<Pool> => {

    const connection = await createPool({
        host: 'Localhost',
        user: 'root',
        password: 'Lekshmi#2308',
        database: 'social_media',
        connectionLimit: 10
    });

    return connection;

}