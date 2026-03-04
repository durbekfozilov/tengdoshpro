import asyncio
from talabahamkorbot.database.db_connect import AsyncSessionLocal
from talabahamkorbot.database.models import Student, ChoyxonaPost
from sqlalchemy import select
from talabahamkorbot.api.community import get_posts

async def main():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Student).where(Student.hemis_login == '395241100325'))
        stu = result.scalars().first()
        
        # Find the post with content "Hello Uzjoku"
        post_result = await session.execute(select(ChoyxonaPost).where(ChoyxonaPost.content.like('%Hello Uzjoku%')))
        post = post_result.scalars().first()
        if post:
            print(f"Found post {post.id} by student {post.student_id}")
            
        # Call get_posts and print exactly what it returns for this post
        posts = await get_posts(
            category=None, faculty_id=None, specialty_name=None, author_id=None, 
            skip=0, limit=20, student=stu, db=session
        )
        for p in posts:
            if p.content and "Hello Uzjoku" in p.content:
                print(f"API Returned is_mine: {p.is_mine}")
                print(f"API Returned author_id: {p.author_id}")
                
if __name__ == "__main__":
    import sys
    sys.path.append("/home/user/talabahamkor/")
    sys.path.append("/home/user/talabahamkor/talabahamkorbot/")
    asyncio.run(main())
